local function pack (cmdline, ...)
  return {
    cmdline=cmdline,
    n=select("#", ...),
    ...
  }
end

if _cmdline=="" then
  if Area.Shell and APanel.Visible and _filename==win.JoinPath(APanel.Path, APanel.Current) then
    print "Shows values returned by specified expression (and stores the values)"
    print "When executed without args - shows previously stored values"
    print "Usage: ret expression"
    print "Export: sh.ret(...): similar to far.Show, but also allowing interactive values browsing"
    return
  end
  --local O = sh._shared.options
  --Plugin.Command(export.GetGlobalInfo().Guid, O.prefix..":=") --Shell QView Info Tree, but not Desktop!
  --export.Open(far.Flags.OPEN_COMMANDLINE, nil, O.prefix..":=")
  sh"LastCmdLineResult"()
elseif _cmdline then
  local ret = pack(_cmdline, sh.eval(_cmdline))
  sh._shared.LastCmdLineResult = ret
  sh.acall(sh.showRet, ret)
else -- export
  return function (...)
    return sh.showRet(pack("", ...))
  end
end
