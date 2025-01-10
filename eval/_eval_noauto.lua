if _cmdline then
  print "This script is used to preconfigure environment before evaluating expression in Execute Dialog"
  print "Functions:"
  print "- disable autoload"
  print "- implement ans/last static substitutes"
  return
end
sh.autoload = false
local bak = sh._shared.LastCmdLineResultBak
ans = bak and bak[1]
last = bak and bak.unpack
_inited = false -- force reinit for [x] Keep env
