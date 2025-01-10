if _cmdline and _cmdline~="" then
  print "Show returned values of last executed script"
  print "Usage: LastCmdLineResult"
  print "Call from other script: sh'LastCmdLineResult'"
  return
end

local res = sh._shared.LastCmdLineResult
if res then
  sh.showRet(res)
else
  far.Message("No script returned values yet or last script failed", sh._shared.info.name)
end
