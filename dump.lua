-- module to be used as tables pretty-printer
-- https://forum.farmanager.com/viewtopic.php?p=140340#p140340
local dump
local success, inspect = pcall(require, "inspect") --https://github.com/kikito/inspect.lua
if success then
  local function process (item)
    if type(item)=="string" then
      if not item:isvalid() or item==("\0"):rep(16) then
        local guid = win.Uuid(item)
        item = guid and guid:isvalid() and "win.Uuid'"..guid:upper().."'"
          or "<non valid utf8>"..item:clean()
      end
    elseif type(item)=="userdata" then
      if bit64.type(item) then
        item = "bit64.new'"..tostring(item).."'"
      else
        item = assert(sh.sharedUtils.safe_tostring(item))
        if not item:find"userdata" then
          item = "<userdata>"..item
        end
      end
    end
    return item
  end

  function dump (v)
    return inspect(v, {process=process})
  end
else
  dump = require"moon".dump
end

local function printRet (...)
  local n = select("#", ...)
  if n==0 then
    print "no values returned"
  elseif n==1 then
    print(dump((...)))
  elseif n~=0 then
    for i=1,n do
      print("value "..i..":", dump(select(i, ...)))
    end
  end
end

if _cmdline=="" then
  print "Dumps specified lua expressions"
  print "Usage: dump lua_expression"
  print "Example:"
  print("  dump dump, {abc=123, true}, math.sin(1)", "=>")
  print(printRet(dump, {abc=123, true}, math.sin(1)))
  print "Export: sh.dump(arg)"
  return

elseif _cmdline then
  printRet(sh.eval(_cmdline))

else -- export
  return dump
end
