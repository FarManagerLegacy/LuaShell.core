local function cutTail (msg, ...)
  for i=1,select("#", ...) do
    local cutfrom = msg:find((select(i, ...)))
    if cutfrom then
      msg = msg:sub(1, cutfrom-1)
      break
    end
  end
  return msg
end

local _shared = sh._shared
local U = sh.sharedUtils
local function smartTrace (err) -- "smart" trace, to make traceback exclude irrelevant levels
  local level = 2
  if _shared.errLevel then -- the error explicitly thrown by our code (sh.sharedUtils.error)
    level = _shared.errLevel + 2
  end
  err = U.formatErr(err)
  local msg = cutTail(
    debug.traceback(err, level),
    "%s*%[C%]: in function 'xpcall'.-$",       -- lua std
    "%s*%(%d+%) global C function 'xpcall'.-$" -- StackTracePlus
  )
  if msg:find"%s+stack traceback:$" or msg:find"%s+Stack Traceback%s+=+$" then
    return err
  end
  return msg
end
local function traceback (err)
  return debug.traceback(U.formatErr(err), 2)
end

local function ErrMessage (msg)
  far.Message(msg, _shared.info.name, nil, "wl")
end
local function ppack (success, ...)
  return success,success and {n=select("#", ...), ...} or ...
end
local function saveRes (res)
  _shared.LastCmdLineResult = res
  if res~=nil then
    _shared.LastCmdLineResultBak = res
  end
end
local function showRet (ret,cmdline,options)
  ret.cmdline = cmdline
  ret.options = options
  --ret.area = area --??
  ret.short = U.shortret(ret)
  ret.unpack = function (i) --??
    return unpack(ret, i or 1, ret.n)
  end
  if options.showret or options.showret_ifany and ret.n>0 then
    sh.showRet(ret)
  elseif ret.n>0 then
    if not options.reopen then
      local title = "Press Enter to browse returned values"
      sh.toast(ret.short, "Result", title, nil, {
        Enter = function () sh.showRet(ret) end
      })
    end
  end
end

local function SetDir (new, old)
  if new==old then return end
  if not win.SetCurrentDir(new) then --?? try short name?
    print("Internal error: unable to set directory: "..new)
  end
end

local function execCmdline (cmdline, opts, done, init)
  opts = opts or {}
  local arg = sh.CommandLineToArgv(cmdline)
  local _cmdline = arg[1] and assert(sh.shiftCmdStr(cmdline, arg[0]), "shiftCmdStr failed") or ""
  local _dir = win.GetCurrentDir()
  local fardir = far.GetCurrentDirectory()
  local path = not opts.expr_only and sh.findScript(arg[0])

  local fn,err
  local env = opts.keepenv
  if path then
    local _sh = env and rawget(env,"sh")
    if _sh then _sh.autoload = nil end -- prev env may come from expr (loadstring), so clean it up
    env = env or {}
    env._cmdline = _cmdline
    fn,err = sh.loadfile(path,env)
  elseif not opts.expr_only and (opts.noexpr or cmdline:sub(1,1)=='"') then
    err = "Script not found: '"..arg[0].."'"
  else
    if env then env._cmdline, env._filename = nil,nil end -- prev env may come from script (loadfile), so clean it up
    env = env or {}
    fn,err = sh.loadstring(cmdline, "eval%s...", env)
  end

  _shared.lastCmd = {
    cmdline=cmdline,
    --_cmdline=_cmdline,
    options=opts,
    --name=path,
    --f=f,
    --arg=arg,
  }
  local isExpr = not path
  if fn then
    err = init and init(env, isExpr)
  end
  if err then
    ErrMessage(err)
    return err
  end
  if not opts.echo_off then
    local prefix = _shared.options[opts.synchro and "prefix_sync" or "prefix"]
    _shared.prnPrompt = ("%s>%s:%s%s"):format(fardir, prefix, U.symbOptions(opts), cmdline)
  end
  --[[ --todo output redirection
  if io.type(io.output())~="file" then io.output(io.stdout) end --??ErrMessage
  --]]
  --local area = Area.Current
  local trace = _shared.options.debug and traceback or smartTrace --????? or postmacro(ErrMessage
  local function run (func)
    if opts.echo_force then print(); U.SetUserScreen() end -- print prompt only
    SetDir(fardir,_dir)
    if isExpr then arg = {} end --??
    local success,ret = ppack(xpcall(func, trace, unpack(arg)))
    sh._shared.errLevel = nil
    --if not O.keep_fcache then fcache = {} end--todo
    SetDir(_dir, fardir)
    U.SetUserScreen()

    if success then
      if opts.showret or ret.n>0 then
        saveRes(ret)
      end
      showRet(ret, cmdline, opts)
      if done then done() end
    else
      saveRes(nil);
      err = ret:gsub("\n\t", "\n   ")
      ErrMessage(err)
      if done then done(err) end
    end
  end
  _shared.GlobalCache = {}
  (opts.synchro and actl.Synchro or mf.postmacro)(run,fn)
end
if _cmdline=="" then
  print "Exposes core functionality of LuaShell"
  print "Usage: execCmdline cmdline"
  print "Export: sh.execCmdline(cmdline,options,onDone,init)"
  print "- cmdline: string; script name (incl. space delimited args), or lua/moon-/yuescript expression"
  print "- options: table; see `hlf:LuaShell.ru.hlf @ExecDlg`"
  print "- onDone: function (runtimeErr: string); useful because execution may be not synchronous"
  print "  In case of runtime error - gets error message"
  print "- init: function (env: table, isExpr: boolean) to run before main script/expression,"
  print "  can be used to init environment."
  print "  If init returns err: string - further execution breaks and err message is displayed."
  print ""
  print "In case of syntax error returns: errmsg"
  print ""
  print "Note:"
  print "  execCmdline is meant for internal use, thus it's API is subject to change!"
elseif _cmdline then
  execCmdline(_cmdline)
else -- export
  return execCmdline
end
