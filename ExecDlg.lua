local F,C = far.Flags, far.Colors

local M = {
  initEnv="&...",
  promptInit="Script name to init expressions &environment (blank to reset)",
  save="S&ave options",
  prompt="Enter &script to execute",
  synchro="S&ynchro",
  expr="E&xpr.",
  echo="&echo",
  showret="Show &result",
  keepenv="&Keep env",
  reopen="Re&open",
  last="Last:",
  noLast="No last result",
}

-- fwd decl
local txtStatus, btnInit, btnLast, btnSave, edtInput
local chk = {}

local function getOptions (hDlg, data)
  local options = {}
  for key,idx in pairs(chk) do
    local state = hDlg:send(F.DM_GETCHECK, idx)
    options[key] = state~=0 and state or nil
  end
  options.noexpr = not options.expr or nil
  options.expr_only = options.expr==1 or nil
  options.expr = nil
  options.echo_off = not options.echo or nil
  options.echo_force = options.echo==1 or nil
  options.echo = nil
  options.showret_ifany = options.showret==2 or nil
  options.showret = options.showret and not options.showret_ifany or nil
  options.initenv = data.initEnv
  options.autostatus = data.autoStatus
  return options
end

local function setOptions (hDlg, options)
  local function set (idx, value)
    if value then
      hDlg:send(F.DM_SETCHECK, idx, value)
    end
  end
  for key,idx in pairs(chk) do set(idx, options[key] and 1) end
  set(chk.expr, options.noexpr and 0 or options.expr_only and 1)
  set(chk.echo, options.echo_off and 0 or options.echo_force and 1)
  set(chk.showret, options.showret and 1 or options.showret_ifany and 2)
end

local Y1,X2, SELECTED, FLAGS = 2,3,6,9
local function initOptions (Items, options)
  for key,idx in pairs(chk) do
    if options[key] then Items[idx][SELECTED] = 1 end
  end
  Items[chk.expr][SELECTED] = options.noexpr and 0 or options.expr_only and 1 or 2
  Items[chk.echo][SELECTED] = options.echo_off and 0 or options.echo_force and 1 or 2
  Items[chk.showret][SELECTED] = options.showret and 1 or options.showret_ifany and 2 or 0
end

local U = sh.sharedUtils

local function importEnv (env, name)
  if not name or name=="" then return end
  if rawget(env, "_inited") then return end
  env._inited = nil
  local path,err = sh.findScript(name)
  if not path then return err end
  local f,success
  f,err = sh.loadfile(path, env)
  if f then
    success, err = pcall(f)
  end
  if not success then
    return U.formatErr(err) --"error processing env init script: "..err.."\n\1\n"..path--??
  end
  env._filename = nil
  env._inited = rawget(env, "_inited")==nil and true
end

local function ppack (success, ...)
  return success,success and {n=select("#", ...), ...} or ...
end
local SCROLL,GET = 2, -1
local function setStatus (hDlg,data)
  if data.autoStatus==false then
    return
  elseif data.autoStatus then
    -- nop
  elseif bit64.band(mf.flock(SCROLL,GET), 1)==0 then
    --todo ?clear
    return
  end
  local expr = hDlg:send(F.DM_GETTEXT, edtInput)
  local env = hDlg:send(F.DM_GETCHECK, chk.keepenv)==1 and sh._shared.lastDlgEnv or {print=function()end}
  local fn,err = sh.loadstring(expr,env)
  err = not fn and err or importEnv(env, data.initEnv)
  local success, ret
  if not err then
    success, ret = ppack(pcall(fn))
    if not success then
      ret, err = nil, U.formatErr(ret)
    end
  end
  data.ret, data.err = ret, err
  if err then -- try to shorten err msg
    err = string.match(err, "sh:findScript: (.+)$")
       or string.match(err, "[^\\]+:%d+: [^\n]+$")
       --or string.match(err, ":1: (.-)$")
       --or string.match(err, "\n(.-)$")
       or err
  end
  local text = ret and (ret.n>0 and U.shortret(ret) or "") or err-- and err:gsub("\n", " ")
  -- bug in prev. versions: https://github.com/FarGroup/FarManager/pull/698#issuecomment-1645522285
  hDlg:send(F.DM_SETTEXT, txtStatus, text)
  local item = data.status
  local state = bit64.band(item[FLAGS], F.DIF_HIDDEN)==F.DIF_HIDDEN and true or false
  if state~=(text=="") then
    item[FLAGS] = text=="" and bit64.bor(item[FLAGS], F.DIF_HIDDEN)
                            or bit64.band(item[FLAGS], bit64.bnot(F.DIF_HIDDEN))
    far.SetDlgItem(hDlg, txtStatus, item)
  end
end

local function shortLast (max)
  local last = sh._shared.LastCmdLineResultBak;
  last = last and last.n>0 and last.short
  local str = last
  if not str then
    str = M.noLast
  elseif str:len() + M.last:len() < max then
    str = M.last.." "..str
  elseif str:len()>max then
    str = str:sub(1, max-1).."…"
  end
  return " "..str.." ", last
end

local O = sh._shared.options
local history = "LuaShellExecDlg"

local idInitGuid = win.Uuid"200B3051-3AAF-4134-8254-0A8568B38DFE"
local Data = {}
local function DlgProc (hDlg,msg,idx,Rec)
  local data = Data[hDlg:rawhandle()]
  if msg==F.DN_INITDIALOG then
    setStatus(hDlg,data)
  elseif msg==F.DN_CLOSE then
    if idx>0 then
      local cmdline = hDlg:send(F.DM_GETTEXT, edtInput)
      hDlg:send(F.DM_ADDHISTORY, edtInput, cmdline)
      local options = getOptions(hDlg,data)
      cmdline,options = U.extractOptions(cmdline,options)
      if cmdline=="" then
        hDlg:send(F.DM_SETTEXT, edtInput, cmdline)
        setOptions(hDlg,options)
        return false -- prevent close
      end
      if options.keepenv then
        local lastEnv = sh._shared.lastDlgEnv
        if lastEnv then lastEnv._cmdline = nil; lastEnv._filename = nil; end
        options.keepenv = lastEnv or {}
      end
      O.execDlgOptions.initenv = data.initEnv
      local err = sh.execCmdline(cmdline, options, function (runtimeErr) -- onDone
        if not hDlg:rawhandle() then return end--fixme
        if options.reopen and not runtimeErr then
          setStatus(hDlg,data)
          local str, hasLast = shortLast(data.width)
          if hasLast then
            hDlg:send(F.DM_SETTEXT, btnLast, str)
            hDlg:send(F.DM_ENABLE, btnLast, 1)
          end
        end
        if options.reopen or runtimeErr then --rerun!!
          --hDlg:send(F.DM_EDITUNCHANGEDFLAG, edtInput, 1) --??depend on 3-State [?] Reopen
          return far.DialogRun(hDlg)
        else -- cleanup
          Data[hDlg:rawhandle()] = nil
          hDlg:ShowDialog(0)
          return far.DialogFree(hDlg)
        end
      end, function (env, isExpr) -- init
        local errmsg
        if isExpr then
          errmsg = importEnv(env, options.initenv)
        end
        sh._shared.lastDlgEnv = options.keepenv
        return errmsg
      end)
      if err then return false end -- prevent close
    else -- cleanup
      Data[hDlg:rawhandle()] = nil
      hDlg:ShowDialog(0)
      far.DialogFree(hDlg)
    end
    return true
  elseif msg==F.DN_BTNCLICK then
    if idx==btnInit then
      local last = data.initEnv or ""
      local name = far.InputBox(
        idInitGuid, sh._shared.info.name, M.promptInit, history.."InitEnv", last, nil, U.HelpTopic"ExecDlg",
        F.FIB_EDITPATH +F.FIB_EDITPATHEXEC +F.FIB_EXPANDENV +F.FIB_ENABLEEMPTY +F.FIB_NOAMPERSAND)
      name = name and name:match"^%s*(.-)%s*$"
      if not name then
        return
      elseif name~=last then
        data.initEnv = name
        name = name~="" and "&. "..name or M.initEnv
        hDlg:send(F.DM_SETTEXT, btnInit, name)
        setStatus(hDlg,data)
      end
      hDlg:send(F.DM_SETFOCUS, edtInput)
    elseif idx==btnSave then
      far.Text()
      win.Sleep(100)
      hDlg:send(F.DM_SETFOCUS, edtInput)
      O.execDlgOptions = getOptions(hDlg,data)
    elseif idx==btnLast then
      if not sh._shared.LastCmdLineResultBak then return end
      sh.showRet(sh._shared.LastCmdLineResultBak, "skipSingleChoice")
    elseif idx==chk.keepenv then
      setStatus(hDlg,data)
    end
  elseif msg==F.DN_CONTROLINPUT then
    local key = far.InputRecordToName(Rec)
    if key=="CtrlE" then
      if data.ret then
        if data.ret.n>0 then sh.showRet(data.ret, "skipSingleChoice") end
      elseif data.err then
        far.Message(data.err, sh._shared.info.name, nil, "wl")
      end
    elseif key=="CtrlEnter" then
      hDlg:send(F.DM_SETCHECK, chk.keepenv, 1)
      hDlg:send(F.DM_SETCHECK, chk.reopen, 1)
    elseif key=="CtrlIns" then
      if idx==btnLast then
        far.CopyToClipboard(sh._shared.LastCmdLineResultBak.short)
        hDlg:send(F.DM_SETFOCUS, edtInput)
        return true
      end
    elseif key=="CtrlK" or key=="F4" and idx==chk.keepenv then
      local env = sh._shared.lastDlgEnv
      if env then sh.browse(env, "Last ENV") end
    elseif key=="CtrlShiftK" or key=="Del" and idx==chk.keepenv then
      sh._shared.lastDlgEnv = nil
      hDlg:send(F.DM_REDRAW)
    elseif key=="CtrlL" then
      hDlg:send(F.DN_BTNCLICK, btnLast)
    elseif key=="Del" and idx==btnInit then
      if data.initEnv~="" and data.initEnv then
        data.initEnv = nil
        hDlg:send(F.DM_SETTEXT, btnInit, M.initEnv)
        hDlg:send(F.DM_SETFOCUS, edtInput)
        setStatus(hDlg,data)
        return true
      end
    elseif key=="F4" and idx==btnInit then
      local name = data.initEnv~="" and data.initEnv
      if name and sh.edit(name)==F.EEC_MODIFIED then
        setStatus(hDlg,data)
      end
    elseif key=="PgDn" then
      hDlg:send(F.DM_SETFOCUS, btnLast)
      return true
    elseif key=="PgUp" then
      if idx==btnSave then
        return hDlg:send(F.DM_SETFOCUS, btnInit)
      end
      hDlg:send(F.DM_SETFOCUS, btnSave)
    elseif key=="ShiftEnter" then
      hDlg:send(F.DM_SETCHECK, chk.showret, 1)
      hDlg:send(F.DM_CLOSE, edtInput)
    elseif key=="ScrollLock" then
      setStatus(hDlg,data)
    end
  elseif msg==F.DN_EDITCHANGE then
    setStatus(hDlg,data)
  elseif msg==F.DN_CTLCOLORDLGITEM then
    if idx==txtStatus then
      local hilite = far.AdvControl(F.ACTL_GETCOLOR, C.COL_DIALOGHIGHLIGHTTEXT)
      if data.ret and data.ret.n>0 and (data.ret.n~=1 or data.ret[1]~=nil) then
        return {hilite}
      end
    elseif idx==btnInit then
      if hDlg:send(F.DM_GETFOCUS)==btnInit then return end
      local disabled = far.AdvControl(F.ACTL_GETCOLOR, C.COL_DIALOGDISABLED)
      return {disabled}
    elseif idx==chk.keepenv then
      if sh._shared.lastDlgEnv then return end
      local disabled = far.AdvControl(F.ACTL_GETCOLOR, C.COL_DIALOGDISABLED)
      return {disabled}
    end
  end
end

local idExecGuid = win.Uuid"31D015D9-477F-4717-9B38-2686F8BF32A5"
local hstExec = {
  default = history,
  [F.WTYPE_COMBOBOX] = history.."Dialog",
  --[F.WTYPE_DESKTOP]  = history.."Panels", --??
  [F.WTYPE_DIALOG]   = history.."Dialog",
  [F.WTYPE_EDITOR]   = history.."Editor",
  --F.WTYPE_GRABBER
  --F.WTYPE_HELP
  --F.WTYPE_HMENU
  [F.WTYPE_PANELS]   = history.."Panels",
  --F.WTYPE_VIEWER
  --F.WTYPE_UNKNOWN
  [F.WTYPE_VMENU]    = history.."Dialog",
  --  FINDFOLDER
}

local function getWinType ()
  local wi = far.AdvControl(F.ACTL_GETWINDOWTYPE)
  return wi and wi.Type
end

local newDlgInfo = sh.DlgHelper

local function ExecDlg (srctext,options)
  local wi = far.AdvControl(F.ACTL_GETWINDOWINFO)
  if wi.Type==F.WTYPE_DIALOG then
    if wi.Id:send(F.DM_GETDIALOGINFO).Id==idExecGuid then
      return
    end
  end
  options = options or O.execDlgOptions
  srctext,options = U.extractOptions(srctext or "", options)

  local origWidth = 86
  local maxW = Far.Width
  local width = math.min(maxW, origWidth)
  local flags, small = 0
  if options.small or width+3*2>maxW then
    small = true
    flags = F.FDLG_SMALLDIALOG
  end
  local II = newDlgInfo {
    width=width,
    Guid=idExecGuid,
    Flags=flags,
    HelpTopic=U.HelpTopic"ExecDlg",
    DlgProc=DlgProc,
  }
  options.initenv = options.initenv~="" and options.initenv or nil
  local _initEnv = options.initenv and "&. "..options.initenv or M.initEnv
                II:add {F.DI_DOUBLEBOX,sh._shared.info.name, {[X2]=-1}}
  btnInit     = II:add {F.DI_BUTTON,   _initEnv, {[Y1]=-1}, F.DIF_BTNNOCLOSE +F.DIF_NOBRACKETS}
  btnSave     = II:add {F.DI_BUTTON,   M.save,   {-M.save:len()-3, -1}, F.DIF_BTNNOCLOSE}
                II:add {F.DI_TEXT,     M.prompt}
  txtStatus   = II:add {F.DI_TEXT,     nil,      {nil, not small and -2 or nil, -1},
                        F.DIF_LEFTTEXT +F.DIF_DISABLE +F.DIF_HIDDEN}
  II:ln() -- -- -- --
  edtInput    = II:add {F.DI_EDIT,     srctext,  {[X2]=-1},
                        F.DIF_DEFAULTBUTTON +F.DIF_HOMEITEM +F.DIF_FOCUS
                       +F.DIF_EDITPATH +F.DIF_EDITPATHEXEC +F.DIF_EDITEXPAND
                       +F.DIF_HISTORY +F.DIF_USELASTHISTORY +F.DIF_MANUALADDHISTORY,
                        History=options.history or hstExec[getWinType()] or hstExec.default}
  II:ln() -- -- -- --
  local function sep ()
                II:add {F.DI_TEXT,     "· ",     {}, F.DIF_CENTERGROUP +F.DIF_DISABLE}
  end
  if width<origWidth then sep = function() end end
  chk.synchro = II:add {F.DI_CHECKBOX, M.synchro,{}, F.DIF_CENTERGROUP};               sep()
  chk.expr    = II:add {F.DI_CHECKBOX, M.expr,   {}, F.DIF_CENTERGROUP +F.DIF_3STATE}; sep()
  chk.echo    = II:add {F.DI_CHECKBOX, M.echo,   {}, F.DIF_CENTERGROUP +F.DIF_3STATE}; sep()
  chk.showret = II:add {F.DI_CHECKBOX, M.showret,{}, F.DIF_CENTERGROUP +F.DIF_3STATE}; sep()
  chk.keepenv = II:add {F.DI_CHECKBOX, M.keepenv,{}, F.DIF_CENTERGROUP};               sep()
  chk.reopen  = II:add {F.DI_CHECKBOX, M.reopen, {}, F.DIF_CENTERGROUP}
  local str, hasLast = shortLast(width)
  btnLast     = II:add {F.DI_BUTTON,   str,      {[Y1]=1}, (hasLast and 0 or F.DIF_DISABLE)
                       +F.DIF_BTNNOCLOSE +F.DIF_NOBRACKETS +F.DIF_CENTERGROUP}
  initOptions(II,options)
  local hDlg = far.DialogInit(II:params())
  Data[hDlg:rawhandle()] = {width=width, status=II[txtStatus], initEnv=options.initenv, autoStatus=options.autostatus}
  return far.DialogRun(hDlg)
end

if _cmdline=="--help" then
  print "Exposes core functionality of LuaShell"
  print "Usage: ExecDlg cmdline"
  print "Export: sh.ExecDlg(cmdline,options)"
  print "- cmdline (string)"
  print "- options (table), see `hlf:LuaShell.ru.hlf @ExecDlg`"
elseif _cmdline then
  sh.acall(ExecDlg, _cmdline)
else -- export
  return ExecDlg
end
