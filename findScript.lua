-- !! needs macros reloading to take effect in LuaShell internals

local exts = {}
for ext in sh._shared.options.pathext:gmatch"[^;]+" do
  exts[#exts+1] = ext
end

local function searchpath (fname,ext)
  --https://learn.microsoft.com/en-us/windows/win32/api/processenv/nf-processenv-searchpathw
  local filename = win.SearchPath(nil,fname,ext)
  if filename then
    return not win.GetFileAttr(filename):find"d" and filename
  end
end
local function findExt (name,extlist)
  for i=1,#extlist do
    local script = searchpath(name, extlist[i])
    if script then return script end
  end
end
local function ExpandEnv (str) return (str:gsub("%%(.-)%%", win.GetEnv)) end
local function findScript (name)
  if type(name)~="string" then
    return nil, "bad argument #1: string expected, got "..type(name)
  end
  name = ExpandEnv(name)
  local fullname = far.ConvertPath(name)
  local file_attr = win.GetFileAttr([[\\?\]]..fullname)
  local script = file_attr and not file_attr:find"d" and fullname
  if not script and not name:find"[/\\]" then
    if name:find(".", 1, "plain") then
      script = searchpath(name)
    else
      script = findExt(name,exts)
    end
  end
  if script then return script end
  return nil, ("Script not found: '%s'"):format(name)
end

if _cmdline=="" then
  print "Finds specified script in %PATH%, expanding env. variables"
  print "and substituting .lua/.moon/.yue extension (if no ext. specified)"
  print "Usage: findScript name"
  print "Example:"
  print("  findScript findScript", "=>", findScript("findScript"))
  print "Exports: sh.findScript(name)"
  print "- returns: full name (or nil and err message)"
elseif _cmdline then
  print(findScript(...))
else -- export
  return findScript
end
