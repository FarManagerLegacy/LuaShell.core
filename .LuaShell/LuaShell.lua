local Info = Info or package.loaded.regscript or function(...) return ... end --luacheck: ignore 113/Info
local nfo = Info { _filename or ...,
  name        = "LuaShell";
  description = "Run lua/moon/yue scripts from command line";
  version     = "0.3"; --https://semver.org/lang/ru/
  author      = "jd";
  url         = "https://forum.farmanager.com/viewtopic.php?f=15&t=10907";
  id          = "718BC6AA-1357-4F85-82BB-CD328F478791";
  minfarversion = {3,0,0,5046,0};
  options     = {
    prefix="luash",
    --prefix_sync="luashs", -- default with "s" added

    -- Specified dir (incl. all subdirectories, except hidden) is added to PATH
    path=win.GetEnv"FARPROFILE"..[[\Macros\utils\]], -- used also as default path to create script

    -- Script extensions to search in PATH
    pathext=".lua;.moon;.yue",

    -- Shortcut to recall last command return values (if any)
    LastResultKey="CtrlShiftL",

    -- Init environment passed to evaluated expressions
    initEval=function (env) -- see loadstring.lua
      env.F = far.Flags
      if rawget(env.sh, "autoload")==nil then
        env.sh.autoload = true
      end
    end,

    -- options for ExecDlg.lua
    execDlgOptions={
      synchro=true,
      --small=true,
      --autostatus=false,
      --initenv="_eval_noauto",
      --...see hlf:LuaShell.ru.hlf @ExecDlg
    },

    --keep_fcache=false, --todo

    --debug=true, -- additional debugging
  };
  --help -- see nfo.help
  --disabled = true;
}
if not nfo or nfo.disabled then return end
local O = nfo.options
assert(O.prefix and type(O.prefix)=="string", "prefix not defined")
O.prefix_sync = O.prefix_sync or O.prefix.."s"
assert(not O.initEval or type(O.initEval)=="function", "initEval must be function")
assert(type(O.execDlgOptions)=="table", "execDlgOptions must be table")

local F = far.Flags
local ptn_path = "^.+[\\/]"
local _path = (...):match(ptn_path)
local _shared = {
  info = nfo,
  path = _path,
  options = O,

  --LastCmdLineResult: see Help / execCmdline.lua / macro

  --lastCmd: see execCmdline.lua / macro

  --prnPrompt: see print_wrapper / execCmdline.lua / sharedUtils.lua

  --prepEnv = ...see below
}

function nfo.help()
  far.ShowHelp(_path, nil, F.FHELP_CUSTOMPATH)
end

local function addpath (VAR, path)
  local var = win.GetEnv(VAR)
  if not var:find(path,1,"plain") then
    --win.SetEnv(VAR,var..";"..path)
    win.SetEnv(VAR,path..";"..var)
  end
end
if O.pathext then
  addpath("pathext", O.pathext)
end

local function addpathRecursive (dir)
  addpath("PATH", dir)
  far.RecursiveSearch(dir, "*>>dH", function (_, subdir)
    addpathRecursive(subdir)
  end)
end

addpathRecursive(assert(O.path, "option 'path' required"))

if not O.path:sub(-1,-1)=="\\" then O.path = O.path.."\\" end --ensure that path string ends with backslash
local sh = loadfile(O.path..[[core\sh.lua]])(_shared)

local U = sh.sharedUtils
CommandLine {
  prefixes=O.prefix..":"..O.prefix_sync;
  description=nfo.description;
  action=function(prefix,cmdline)
    local options = {
      synchro = prefix==O.prefix_sync
    }
    cmdline, options = U.extractOptions(cmdline, options)
    if cmdline=="" then
      if options.showret then
        sh"LastCmdLineResult"()
      else
        far.ShowHelp(_path, "Cmdline", F.FHELP_CUSTOMPATH)
      end
    else
      sh.execCmdline(cmdline, options)
    end
  end;
}

Macro { description="LuaShell: show values returned by last script";
  area="Common"; key=O.LastResultKey;
  priority=40;
  id="8EA737C4-6295-445A-85B7-DB4AB025D95A";
  action=function() sh"LastCmdLineResult"() end;
}

Macro { description="LuaShell: repeat last command";
  area="Common"; key="CtrlAltG CtrlG:Double";
  priority=40;
  id="CEE70A90-6153-4C4A-AE09-306A9627E19D";
  action=function()
    local lastCmd = _shared.lastCmd
    if not lastCmd then
      far.Message("No last command to repeat", nfo.name, nil, "wl")
    else
      sh.execCmdline(lastCmd.cmdline, lastCmd.options)
    end
  end;
}

local function ExecDlg() mf.acall(sh.ExecDlg) end --for macros

local scu_title = "LuaShell commandline"
local _panels = "Shell Info QView Tree"
Macro { description=scu_title;
  area=_panels; key="CtrlG:Hold";
  id="5ECA5D8A-1654-4FE0-824A-09C6B2022673";
  action=ExecDlg;
}

local _exceptPanels = {}
(_panels.." Current ShellAutoCompletion DialigAutoCompletion")
  :gsub("%w+", function (area) _exceptPanels[area] = true end)
for area in pairs(Area.properties) do
  if not _exceptPanels[area] then table.insert(_exceptPanels, area) end
end
Macro { description=scu_title;
  area=table.concat(_exceptPanels, " "); key="CtrlG";
  priority=40;
  id="231FE85C-FDDD-4AB8-8732-BCE2EDAC522D";
  action=ExecDlg;
}

Macro { description=scu_title.." (pick from Editor)";
  area="Editor"; key="CtrlG:Hold";
  priority=40;
  id="FA5C6569-A038-482B-ABE1-6E4AFECA574B";
  action=function()
    local str = Object.Selected and Editor.SelValue
    if not str then
      local curline = Editor.Value
      str = curline:match"%-%-([^-].-)$" or curline --pick comment
      str = str:match"%S.*$" --trim
    end
    mf.acall(sh.ExecDlg, str, {
      autostatus=true,
      initenv="_eval_noauto",
    })
  end;
}

Macro { description=scu_title.." (Common)";
  area="Common"; key="CtrlShiftG";
  priority=40;
  id="C4F7A657-F181-4CE7-8B05-ECD445F22598";
  action=ExecDlg;
}

local function isEditPathExec()
  if Dlg.ItemType==F.DI_EDIT then
    local hDlg = far.AdvControl(F.ACTL_GETWINDOWINFO).Id
    local Flags = hDlg:send(F.DM_GETDLGITEM, Dlg.CurPos)[9]
    return bit64.band(Flags, F.DIF_EDITPATHEXEC)~=0
  end
end
local trim_ptn = "^=?[*@]?(.+)$"
Macro { description="LuaShell: open script in viewer";
  area="Dialog"; key="F3";
  priority=60;
  id="AD157F4B-D4E4-48C5-A3FB-6C48E2CC7F98";
  condition=isEditPathExec;
  action=function()
    local cmdline = Dlg.GetValue():match(trim_ptn)
    if not cmdline then return end
    local arg = sh.CommandLineToArgv(cmdline)
    local script,msg = sh.findScript(arg[0])
    if not script then
      far.Message(msg, nfo.name, nil, "wl")
      return
    end
    viewer.Viewer(script)--,nil,nil,nil,nil,nil,F.VF_NONMODAL+F.VF_IMMEDIATERETURN) --would make sense in nonmodal dlg
  end;
}

Macro { description="LuaShell: open script in editor";
  area="Dialog"; key="F4";
  priority=60;
  id="48E2B19E-8A3E-4E56-8E31-90B494164711";
  condition=isEditPathExec;
  action=function()
    local cmdline = Dlg.GetValue():match(trim_ptn)
    if not cmdline then return end
    local arg = sh.CommandLineToArgv(cmdline)
    sh.edit(arg[0])
  end;
}

Macro { description="LuaShell: open script under cursor";
  area="Editor"; key="F4"; filemask="*.lua;*.moon;*.yue";
  id="CB8B43C7-946E-444E-9D3D-CB32F2D9BF63";
  action=function()
    local script = sh.pick()
    if script then
      sh.edit(script)
    end
  end;
}
