local F = far.Flags
local function acall (func, ...)
  -- used to be necessary to allow autocompletion (before Far 3 build 6074)
  -- now just prevents macro execution mark "P"
  local state = far.MacroGetState()
  if state==F.MACROSTATE_EXECUTING or state==F.MACROSTATE_EXECUTING_COMMON then
    mf.acall(func, ...)
  else
    func(...)
  end
end

if _cmdline then
  print "Function to call specified func asynchronously (when run from macro)."
  print "Export: sh.acall(func, ...)"
  return
end

return acall -- export
