local showRetId = win.Uuid"1B80D345-12C0-4F31-BF63-D9EC13B8F830"
local toBrowse = {["table"]=true, ["function"]=true, ["thread"]=true}
local function showRet (ret, skipSingleChoice)
  if type(ret)~="table" then
    error("bad argument #1 to sh.showRet (table expected, got "..type(ret)..")")
  end
  ret.n = ret.n or #ret
  if ret.n==0 then
    local msg = ret.cmdline and ret.cmdline.."\n\1\nNo values returned" or "No values"
    far.Message(msg, _filename:match"[^\\]+$")
    return
  end
  if ret.n==1 and toBrowse[type(ret[1])] then
    if skipSingleChoice then -- skip list displaying (dump value immediately)
      sh.browse(ret[1], ret.cmdline)
      return
    else
      mf.postmacro(Keys,"Enter")
    end
  end
  local Items = far.MakeMenuItems(unpack(ret, 1, ret.n))
  local Props = {
    Title = "",
    Bottom = "Enter, Ctrl+Ins",
    Id = showRetId,
    HelpTopic = sh.sharedUtils.HelpTopic"ShowRet",
  }
  local BrKeys = "CtrlIns"
  if ret.cmdline then
    Props.Title = ret.cmdline
    Props.Bottom = Props.Bottom..", Ctrl+E (recall)"
    BrKeys = BrKeys.." CtrlE"
  end
  repeat
    local choosen,pos = far.Menu(Props, Items, BrKeys)
    if choosen then
      Props.SelectIndex = pos
      if choosen.BreakKey=="CtrlIns" then
        if pos~=0 then
          local arg = Items[pos].arg
          local str = (type(arg)=="table" and sh.dump or tostring)(arg)
          if not far.CopyToClipboard(str) then
            far.CopyToClipboard(arg)
          end
        end
      elseif choosen.BreakKey=="CtrlE" then
        choosen = false
        sh.ExecDlg(ret.cmdline, ret.options)
      elseif toBrowse[type(choosen.arg)] then
        sh.browse(choosen.arg, "value "..tostring(pos))
      end
    end
  until not choosen
end

if _cmdline then
  print "Utility to browse arrays"
  print "Export: sh.showRet(ret)"
  print "- ret: table, array of values, with optional hash part:"
  print "  .n: number of values (to be able to keep nils)"
  print "  .cmdline: string used to get ret values (for title and ability to recall)"
  print "  .options: table, providing execution options"
  print "Used internally for browsing values returned by functions calls"
  print "Note: there is standalone utility for this purpose - see ret.lua"
  return
end

return showRet -- export
