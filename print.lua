local function _print (...)
  local n = select("#", ...)
  if n>0 then
    win.WriteConsole(tostring(...))
    for i=2,n do
      win.WriteConsole("\t")
      win.WriteConsole(tostring(select(i, ...)))
    end
  end
  win.WriteConsole("\n")
end

local C = far.Colors
local F = far.Flags
local function printPrompt (str)
  local cPrefix = far.AdvControl(F.ACTL_GETCOLOR, C.COL_COMMANDLINEPREFIX)
  local cCmdline = far.AdvControl(F.ACTL_GETCOLOR, C.COL_COMMANDLINE)
  local Y = far.AdvControl(F.ACTL_GETCURSORPOS).Y
  local prefix,cmdline = str:match"^(.->)(.+)"
  far.Text(0, Y, cPrefix, prefix)
  far.Text(prefix:len(), Y, cCmdline, cmdline)
  far.Text()
  _print()
end

local U = sh.sharedUtils
local function print_wrapper (...)
  U.GetUserScreen()
  if sh._shared.prnPrompt then
    --_print(_shared.prnPrompt)
    printPrompt(sh._shared.prnPrompt)
    sh._shared.prnPrompt = false
  end
  _print(...)
end
local print = print_wrapper

if _cmdline=="" then
  print "Analog of the standard Lua function print, based on win.WriteConsole."
  print "Outputs text to a buffer under panels (panels are turned off and on automatically after the script finishes)."
elseif _cmdline then
  print(...)
else --export
  return print
end