if _cmdline and APanel.Visible and Area.Shell and _filename==win.JoinPath(APanel.Path, APanel.Current) then
  far.ShowHelp(sh._shared.path, "ExecDlg")
  return
end
nocache = true
return assert(sh._shared.LastCmdLineResultBak, "no last expr")[1]
