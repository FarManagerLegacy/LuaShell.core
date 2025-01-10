local ffi = require"ffi"
local Shell32,C = ffi.load"Shell32",ffi.C
ffi.cdef[[
// https://learn.microsoft.com/windows/win32/api/shellapi/nf-shellapi-commandlinetoargvw
LPWSTR * CommandLineToArgvW(
  LPCWSTR lpCmdLine,
  int     *pNumArgs  // [out]
);
// https://learn.microsoft.com/windows/win32/api/winbase/nf-winbase-lstrlenw
int lstrlenW(
  LPCWSTR lpString
);
]]

local wsize = ffi.sizeof"wchar_t"
local function CommandLineToArgv (CommandLine)
  local pNumArgs = ffi.new("int[1]")
  local CommandlineW = win.Utf8ToUtf16(CommandLine).."\0"
  local Argv = Shell32.CommandLineToArgvW(ffi.cast("LPCWSTR",CommandlineW), pNumArgs)
  if Argv~=nil then
    local argv = {}
    for i=0,pNumArgs[0]-1 do
      argv[i] = win.Utf16ToUtf8(ffi.string(Argv[i], C.lstrlenW(Argv[i])*wsize))
    end
    return argv
  end
  error("Internal error: CommandLineToArgvW failed")
end

if _cmdline=="" then
  print "Export: arg[] = sh.CommandLineToArgv(string)"
  print "Splits commandline into separate arguments"
  print "Example:"
  print("sh.CommandLineToArgv([["..[[1 "2 a" \"3" "b\"]].."]])", "=>",
        sh.dump(CommandLineToArgv([[1 "2 a" \"3" "b\"]])))
elseif _cmdline then -- test
  print(unpack(CommandLineToArgv(_cmdline), 0))
else -- export
  return CommandLineToArgv
end
