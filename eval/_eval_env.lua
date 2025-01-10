if _cmdline then
  print "This script is used to preconfigure environment before evaluating expression in Execute Dialog"
  print "Functions:"
  print "- provide math functions to global namespace"
  print "- disable autoload"
  print "- implement ans/last substitutes"
  return
end

local __index = {
  math,
}

local function assert2 (value, ...)
  if value then
    return value, ...
  end
  error(..., 4)
end
function sh.autoload (name)
  if name=="ans" then
    return assert2(sh._shared.LastCmdLineResultBak, "ans: no last expr")[1]
  elseif name=="last" then
    return assert2(sh._shared.LastCmdLineResultBak, "last: no last expr").unpack
  end
  for _,t in ipairs(__index) do
    if t[name]~=nil then return t[name] end
  end
  return nil -- << to prevent scripts autoload for unknown identifiers
end
