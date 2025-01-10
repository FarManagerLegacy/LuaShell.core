local U = sh.sharedUtils

local function eval (expr, env, ...)
  if not expr then U.error("eval: expression expected", 2) end
  if env and type(env)~="table" then
    U.error("eval: bad argument #2 (table expected, got "..type(env)..")", 2)
  end
  local fn,err1 = sh.loadstring(expr, "eval%s...", env)
  local msg_runerr = "eval:\n"..expr.."\n\1\n"
  if not fn then
    U.error(msg_runerr..err1, 2)
  end
  if sh._shared.options.debug then
    return fn(...)
  end
  return U.assertX(1, msg_runerr, pcall(fn, ...))
end

if not _cmdline then --export
  return eval
end
-----------------------------
local function printRet (...)
  local n = select("#", ...)
  if n==0 then
    print "<no return value>"
  elseif n==1 then
    print("="..sh.dump(...))
  else
    for i = 1,n do
      print("value "..i..":", sh.dump((select(i, ...))))
    end
  end
end

local init = "_eval_extra.lua"
if _cmdline=="" then
  if Area.Editor then --sel or curline
    local str = Object.Selected and Editor.SelValue
    if not str then
      local curline = Editor.Value
      str = curline:match"%-%-([^-].-)$" or curline --pick comment
      str = str:match"%S.*$" --trim
    end
    sh.ExecDlg(str, {
      initenv=init,
    })
  else
    print "Export: sh.eval(expr[,env[,...]])"
    print "Evaluate a string as a Lua/moon/yue expression (optionally passing a table with environment and arguments)."
    print "Useful both:"
    print "...for actual computations: 1+math.sin(2)"
    print [[...and for passing any Lua values: _G, Far, 123, "abc", {k="v"}, function() print"hello" end, ...]]
    print [[Examples of usage can be found in utils\core\eval\README.]]
    print ""
    print "Usage in commandline:"
    print "Print values returned by specified expression"
    print "When executed without args - prints previously stored values"
    print "In editor: pick selection / current line for evaluation in dialog"
    print ("Note: beeing executed in cmdline imports user-defined functions from "..init)
    local res = sh._shared.LastCmdLineResult
    if res then
      print(res.cmdline)
      printRet(unpack(res, 1, res.n))
    end
  end
  return
else
  local function saveRes (...)
    local res = {n=select("#", ...), ...}
    res.cmdline = _cmdline
    res.options = {initenv=init}
    res.short = U.shortret(res)
    res.unpack = function (i)
      return unpack(res, i or 1, res.n)
    end
    sh._shared.LastCmdLineResult = res
    sh._shared.LastCmdLineResultBak = res
    return ...
  end
  local expr = _cmdline:match"^=(.*)$" or _cmdline
  print(expr)
  local env = {}
  local ret = sh(init,env)()
  sh._shared.LastCmdLineResult = nil -- keep nil in case of error
  printRet(saveRes(eval(expr, ret or env)))
end
