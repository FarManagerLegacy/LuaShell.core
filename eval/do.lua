if _cmdline=="" then
  print "Executes specified lua expression"
  print "Usage: do expression"
  print "Example:"
  print('  do print("abc", 123, {}, true, function() end)', "=>",
        "\nabc", 123, {}, true, function() end)
  return
end

return sh.eval(_cmdline)
