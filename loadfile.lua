local function loadFile (fullname,env)
  --??cache
  if type(fullname)~="string" then
    error("bad argument #1 to sh.loadfile (string expected, got "..type(fullname)..")", 2)
  end
  local _loadfile = loadfile
  if fullname:lower():match"%.yue$" then
    _loadfile = require"yue".loadfile
  elseif fullname:lower():match"%.moon$" then
    _loadfile = require"moonscript".loadfile
  end
  local f,errmsg = _loadfile(fullname)
  if not f then return nil,errmsg end
  env = sh(env or {}) --prepEnv !!no arg check
  env._filename = fullname
  return setfenv(f,env)
end

if _cmdline=="" then
  print "Export: sh.loadfile (filename[, env])"
  print "Used internally for loading script files. Similar to Lua 5.2 `loadfile`,"
  print "but is capable to load moon/yue as well, detecting code language by file's extension."
  print "Provides `sh` module, injects `_filename` variable, and sets up some other routines via special metatable."
  print "Note: it is more practical to use `sh` module instead for the most user tasks."
elseif _cmdline then -- test
  local fn = assert(loadFile(_cmdline))
  print("Successfully loaded "..tostring(fn))
else -- export
  return loadFile
end
