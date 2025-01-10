local _shared = ... or sh._shared
local O = _shared.options

local error = error
local assertX, findScript, loadFile --fwd. decl.

local function getScript (name,env,level)
  local fullname,err = findScript(name)
  if not fullname then -- not found
    error("sh:findScript: "..err, level+1)
  end
  local fn,err1 = loadFile(fullname,env)
  if not fn then -- load err
    error("sh:loadfile: '"..name.."'\n\1\n"..err1, level+1)
  end
  return fn,fullname
end

_shared.GlobalCache = {}
local function indexScript (cache, name, level)
  if not O.debug and _shared.GlobalCache[name] then
    cache[name] = _shared.GlobalCache[name]
    return _shared.GlobalCache[name]
  end
  local env = {}
  local fn = getScript(name, env, (level or 1)+1)
  local ret, ret2
  if O.debug or not assertX then
    ret = fn(name)
  else
    local msg_runerr = ("sh: trying to load script '%s'...\n"):format(name)
    ret, ret2 = assertX(2, msg_runerr.."\1\n", pcall(fn, name))
  end
  if not O.debug then
    if not (ret2=="nocache" --undoc
            or rawget(env, "nocache")) then
      cache[name] = ret
      _shared.GlobalCache[name] = ret
    end
  end
  return ret
end

local print_wrapper, prepEnv --fwd decl
local mt_sh = { -- sh. namespace support
  __index=indexScript,         -- sh.scriptname to run "scriptname('scriptname')"
  __call=function (_,name,env) -- sh"scriptname" to load "scriptname"
    if not name then
      error("sh: name not specified", 2)
    elseif type(name)=="table" then -- sh(env) to prep script env !!special
      return prepEnv(name)
    elseif type(name)~="string" then
      error("sh: name must be string", 2)
    elseif name:match"^%s-$" then
      error("sh: name is empty", 2)
    end
    if env~=nil and type(env)~="table" then
      error("sh: bad argument #2: 'env' must be table", 2)
    end
    return getScript(name,env,1)
  end;
}
local function newSh ()
  return setmetatable({
    _shared=_shared,
    print=print_wrapper
  }, mt_sh)
end
local sh = newSh()                             -- sh namespace for internal purposes
package.preload.sh = function () return sh end -- expose sh for plain macros (via require)

local mt_autoload = {}
do
  local blacklisted = {
    ReloadDefaultScript=true,
    RecreateLuaState=true,
    IsLuaStateRecreated=true,
    _filename=true,
    _cmdline=true,
  }
  for k,_ in pairs(getfenv()) do blacklisted[k] = true end -- blacklist functions-loaders (Macro, Event, ...)

  local function checkRet (...)
    return select("#", ...)~=0, ...
  end
  function mt_autoload:__index (name)
    if _G[name]~=nil then
      return _G[name]
    elseif not blacklisted[name] then
      local _sh = rawget(self, "sh")
      if rawget(_sh, "autoload") then
        if type(_sh.autoload)=="function" then
          local hasRet, ret = checkRet(_sh.autoload(name))
          if hasRet then
            self[name] = ret -- cache
            return ret
          end
        end
        return indexScript(self,name)
      end
    end
  end
end

function prepEnv (env)
  env.sh = rawget(env, "sh") or newSh()
  env.print = env.print or print_wrapper -- override _G.print (to prevent this you can pre-set 'print' in env)
  if not getmetatable(env) then
    setmetatable(env, mt_autoload)
  end
  return env
end

-- temporary bootstrap stuff
loadFile = function (fullpath)
  local env = prepEnv({})
  return setfenv(loadfile(fullpath), env)
end
findScript = function (name) return O.path.."core\\"..name..".lua" end
loadFile = sh.loadfile
error = sh.sharedUtils.error
assertX = sh.sharedUtils.assertX
print_wrapper = sh.print
findScript = sh.findScript

if _cmdline then
  return sh.browse({sh{}}, "test sh environment")
end
return sh
