if _cmdline then
  far.ShowHelp(sh._shared.path, "ExecDlg")
  return
end
nocache = true
return assert(sh._shared.LastCmdLineResultBak, "no last expr").unpack
