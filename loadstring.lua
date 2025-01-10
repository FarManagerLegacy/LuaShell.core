local function loadString (str,chunkname,env)
  local template
  if type(str)~="string" then
    error("bad argument #1 to sh.loadstring (string expected, got "..type(str)..")", 2)
  elseif type(chunkname)=="table" then
    env,chunkname = chunkname,nil
  elseif type(chunkname)=="string" then
    if chunkname:find("%s", 1, "plain") then
      template = chunkname
    end
  elseif chunkname~=nil then
    error("bad argument #2 to sh.loadstring (string expected, got "..type(chunkname)..")", 2)
  end
  env = sh(env or {}) --prepEnv !!no arg check
  local O = sh._shared.options
  if O.initEval then
    --?? setfenv(O.initEval, env)
    local success, err = pcall(O.initEval, env)
    if not success then
      return nil, sh.sharedUtils.formatErr(err)
    end
  end
  local f,err1
  chunkname = template and template:format":return " or chunkname
  f = loadstring("return "..str, chunkname, nil, env)                 -- try return
  if not f then
    -- only this err message is used
    chunkname = template and template:format":" or chunkname
    f,err1 = loadstring(str, chunkname, nil, env)                     -- try plain lua
  end
  if not f then
    chunkname = template and template:format" (moon):" or chunkname
    f = require"moonscript".loadstring(str, chunkname, nil, env, nil) -- try moonscript
  end
  if not f and pcall(require,"yue") then
    chunkname = template and template:format" (yue):" or chunkname
    f = require"yue".loadstring(str, chunkname, nil, env, nil)        -- try yuescript
  end
  return f,err1
end

if _cmdline=="" then
  print "Export: sh.loadstring(string[,chunkname][,env])"
  print "Function that is used internally for loading code chunks. Similar to Lua 5.2 `load`,"
  print "but is capable to load moon/yue as well, auto-detecting code language."
  print "Tries to return the result of code execution."
  print "Initialises environment with LuaShell's `options.initEnv` function,"
  print "provides `sh` module, and sets up some other routines via special metatable."
  print "Note: it is more practical to use sh.eval for the most user tasks."
elseif _cmdline then -- test
  local fn = assert(loadString(_cmdline))
  print("Successfully loaded "..tostring(fn))
else -- export
  return loadString
end
