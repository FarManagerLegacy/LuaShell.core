local id = win.Uuid"67CD7342-31A5-4233-927F-E15D53515A8F"
local F = far.Flags
local DEF_TIMEOUT = 700
local EXTRA_TIMEOUT = 300
sh._shared._toastN = 0

local function trim (str, width)
  if not str or str:len()<=width then return str end
  return str:sub(1, width-1).."…"
end

local function Toast (text, title, bottom, timeout, keys)
  local r = far.AdvControl(F.ACTL_GETFARRECT)
  local maxX, maxY = r.Right-r.Left+1, r.Bottom-r.Top+1
  if type(text)=="table" then
    local t = text
    text,title,bottom,timeout,keys = t.text, t.title, t.bottom, t.timeout, t.keys
  elseif type(bottom)~="string" then -- shift
    bottom,timeout,keys = nil,bottom,timeout
  end
  assert(text, "text not specified")
  if type(bottom)=="string" then bottom = " "..bottom.." " end -- pad bottom title
  if type(timeout)=="string" then --commandline
    timeout = sh.eval(timeout)
  end
  local test = win.Uuid()
  local len = math.max(text:len(), title and title:len() or 0, bottom and bottom:len() or 0)
  len = math.min(maxX-2, len)
  local items = {
    {F.DI_SINGLEBOX,0,0,len+2,3,0,0,0,                0, trim(title,len)},
    {F.DI_TEXT,     2,1,    0,1,0,0,0,F.DIF_CENTERGROUP, trim(text,len)},
    {F.DI_TEXT,     0,2,    0,1,0,0,0,F.DIF_CENTERGROUP, trim(bottom,len)},
  }
  local function processKey (key, Rec)
    if keys and keys[key] then
      keys[key](Rec)
    else
      mf.postmacro(Keys,key)
    end
  end
  local onInit, onClose
  if timeout~=false and timeout~=0 then
    local timer
    function onInit (hDlg)
      timer = far.Timer(timeout or DEF_TIMEOUT, function (t)
        t:Close()
        hDlg:send(F.DM_CLOSE)
        processKey(mf.waitkey(EXTRA_TIMEOUT)) -- wait for late user reaction
      end)
    end
    function onClose ()
      timer:Close()
    end
  end
  sh._shared._toastN = sh._shared._toastN+1 --fixme
  local y = maxY
  y = math.max(y-4*sh._shared._toastN+1, 2)
  return far.DialogInit(id, -1, y, len+2, y+2, nil, items, F.FDLG_NONMODAL, function (hDlg, Msg, _, Rec)
    if Msg==F.DN_INITDIALOG then
      if onInit then onInit(hDlg) end
    elseif Msg==F.DN_CLOSE then
      sh._shared._toastN = sh._shared._toastN-1
      if onClose then onClose() end
    elseif Msg==F.DN_CONTROLINPUT then
      local key = far.InputRecordToName(Rec)
      hDlg:send(F.DM_CLOSE)
      if key=="Esc" then return end
      processKey(key, Rec)
    end
  end)
end

if _cmdline=="" then
  print "Displays toast notification"
  print "Usage: toast text [title [bottom [timeout]]])"
  print "Export: sh.toast(text[,title[,bottom][,timeout[,keys]]])"
  print "- timeout: number (ms) | false | nil (==700)"
  print "- keys: table, {<key>: function, ...}"
  print "Toast notification is closed automatically by timeout, or if any key is pressed"

elseif _cmdline=="test" then
  Toast "Testing toast 1..."
  Toast("Testing toast 2...", "title", "bottom", DEF_TIMEOUT+200)
  Toast{
    text="Testing toast 3...",
    bottom="press Enter",
    timeout=false,
    keys={ Enter = function () far.Message"Enter pressed" end }
  }
elseif _cmdline then
  local text,title,bottom,timeout = ...
  if text:find":" then
    Toast(sh.eval(_cmdline))
    return
  end
  bottom = tonumber(bottom,10) or bottom
  Toast(text,title,bottom,timeout)
else -- export
  return Toast
end
