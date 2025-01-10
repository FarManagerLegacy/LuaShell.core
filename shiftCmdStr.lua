local function shiftCmdStr (cmdline,arg0) -- exclude arg[0] !! not reliably enough
  local arg_0
  if cmdline:sub(1,1)=='"' then arg_0 = '"'..arg0..'"' else arg_0 = arg0 end
  local _len = arg_0:len()
  if cmdline:sub(1,_len)==arg_0 then
    return cmdline:sub(_len+2):match"(%S.*)$"
  end
end

if _cmdline=="" then
  print "Tries to cut 1st argument from cmdline string"
  print "Export: str = sh.shiftCmdStr(cmdline,arg0)"
elseif _cmdline then -- test
  print(shiftCmdStr(_cmdline, ...))
else -- export
  return shiftCmdStr
end
