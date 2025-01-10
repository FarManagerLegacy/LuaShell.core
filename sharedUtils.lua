local F = far.Flags
local U = {}
local function inUserScreen ()
  local wi = far.AdvControl(F.ACTL_GETWINDOWINFO)
  return wi.Type==F.WTYPE_DESKTOP and band(wi.Flags, F.WIF_MODAL)~=0
end

function U.GetUserScreen () -- hide panels, preventing nested calls
  if not inUserScreen() then panel.GetUserScreen() end
end

function U.SetUserScreen () -- restore panels if hided
  sh._shared.prnPrompt = false
  far.Text() --https://bugs.farmanager.com/view.php?id=3524
  while inUserScreen() do panel.SetUserScreen() end
end

function U.safe_tostring (obj)
  local success, str = pcall(tostring, obj)
  if not success then
    if type(str)~="string" then
      str = string.format("(error object is a %s value)", type(str))
    end
    return nil, str
  elseif type(str)~="string" then
    return nil, "'__tostring' must return a string"
  else
    return str
  end
end

function U.formatErr (obj)
  local tname = type(obj)
  if tname=="number" then
    obj = tostring(obj)
  elseif tname~="string" then
    local mt = debug.getmetatable(obj)
    if mt and mt.__tostring~=nil then
      obj = U.safe_tostring(obj) or "error in error handling"
    else
      obj = string.format("(error object is a %s value)", tname)
    end
  end
  return obj
end

function U.error (msg, level) -- raise error and pass level# to be catched by execCmdline.lua/smartTrace
  level = level + 1
  sh._shared.errLevel = level
  U.SetUserScreen()
  error(msg, level)
end

function U.assertX (level, prefixMsg, success, ...)
  if success then
    return ...
  end
  U.error(prefixMsg..U.formatErr(...), level+1) -- rewrite err msg
end

function U.HelpTopic (s) -- compose help topic string using path to LuaShell folder
  return ("<%s>%s"):format(sh._shared.path, s)
end

function U.shortret (ret) -- shorten ret to display in one line
  local tmp = {}
  for i=1,ret.n do
    local t = sh.moondump(ret[i])
    t = string.gsub(t, "function: 0x[%da-f]+", "func…") -- ƒ𝑓
    t = string.gsub(t, "function: builtin", "func")
    t = string.gsub(t, "\\\\", "\\")
    tmp[i] = t:clean()
  end
  return table.concat(tmp, ",")
end

local keys = {"noexpr","showret","showret_ifany","echo_off","echo_force"}
local symbs = {
  noexpr=":",
  showret="=",
  showret_ifany="?",
  echo_off="@",
  echo_force="*",
}
local xor = {
  noexpr="expr_only", -- no pair
  showret="showret_ifany",
  showret_ifany="showret",
  echo_off="echo_force",
  echo_force="echo_off",
}

local function trim (str,param,options)
  if str:sub(1,1)==symbs[param] then
    options[param] = true
    local clear = xor[param]
    if clear then options[clear] = nil end
    return str:sub(2)
  end
end

function U.extractOptions (cmdline, opts) -- parse execution options out of special symbols in commandline"
  opts = opts or {}
  for _,k in ipairs(keys) do
    cmdline = trim(cmdline,k,opts) or cmdline
  end
  return cmdline, opts
end

function U.symbOptions (opts) -- transform options to special symbols
  local symb = ""
  for _,k in ipairs(keys) do
    if opts[k] then symb = symb..symbs[k] end
  end
  return symb
end

if _cmdline=="" then
  print "Internal functions of LuaShell and core scripts"
  print("Export:", sh.dump(U))
  print ""
  print "Can be tested using following syntax:"
  print "  sharedUtils <fname> <arg>"
elseif U[...] then -- test
  local fn = U[...]
  local arg = sh.shiftCmdStr(_cmdline, ...)
  if fn==U.shortret then
   local function pack (...)
     return {n=select("#", ...), ...}
   end
    print(fn(pack(sh.eval(arg))))
    return
  elseif fn==U.symbOptions then
    arg = sh.eval(arg)
  end
  sh.ret(fn(arg))
else -- export
  return U
end
