local F = far.Flags

--> begin of Dlg helper <-- v0.1
local function norm (arg, base, align)
  if not arg or arg==0 then
    return base
  elseif type(arg)=="string" then
    return base + tonumber(arg)
  end
  return base + arg + (arg<0 and align or 0)
end

-- .add(item): method; allows defining items in a convenient way.
-- item: table; accepts the same parameters as outlined in the tFarDialogItem article
-- hh mk:@MSITStore:%FARHOME%\Encyclopedia\luafar_manual.chm::/295.html
-- In contrast to tFarDialogItem the parameters must be named (as table fields).
-- Also, the five arguments can be arranged positionally:
--     Type, Data (Label/Text), {coords}, Flags, Selected/ListItems
-- Instead of X1,Y1,X2,Y2 there is an array - coords: {X1,X2,Y1,Y2}
-- * coords table is optional (as well as any value it contains).
--   Defaults are: X1=0; Y1="current" line; X2=X1, Y2=Y1.
-- * The values specified in coords should be relative to the "working area".
--   This eliminates the need to consider the dialog frame and outer margins manually,
--   so coords do not depend neither on FDLG_SMALLDIALOG flag, nor on presence of a frame.
-- * If the first added item is a frame (DI_SINGLEBOX or DI_DOUBLEBOX),
--   then the "working area" is set to space available inside it.
-- * Working area params are: x0, y0, width and y ("current" line)
-- * X1,X2 positions are relative to the start of the "working area" (self.x0).
-- * negative value is interpreted as a position relative to the right border.
--   To avoid this adjustment, the negative value should be specified as a string.
-- * Y1,Y2 positions are relative to the "current" line (self.y).
-- Additionally:
-- * item automatically obtains an .idx field
-- * when optional .name parameter is specified, the item is placed into a .names table,
--   which is available as a field of dialog info object.
local function add (self,item)
  item[6] = item[5] or item.Selected or item.ListItems or 0
  item[7] = item.History
  item[8] = item.Mask
  item[9] = item[4] or item.Flags
  item[10] = item[2] or item.Data
  item[11] = item.MaxLength
  item[12] = item.UserData
  local c = item[3] or item.coords or {}
  local coords = {}
  coords[1] = norm(c[1], self.x0, self.width) -- X1
  coords[2] = norm(c[2], self.y0+self.y)      -- Y1
  coords[3] = norm(c[3], self.x0, self.width) -- X2
  coords[4] = not c[4] and coords[2]          -- Y2==Y1
           or norm(self, c[4], self.y0+self.y)
  item[1] = item[1] or item.Type
  for i=2,5 do item[i] = coords[i-1] end
  local i = #self+1; item.idx = i; self[i] = item;
  if i==1 and (item[1]==F.DI_SINGLEBOX or item[1]==F.DI_DOUBLEBOX) then
    self.x0, self.y0, self.width = self.x0+2, self.y0+1, self.width-2*2 -- accomodate "working area" params
  end
  if item.name then
    if self.names[item.name] then
      far.Message("Duplicated item name: "..item.name, "Error in config", nil ,"lw")
    else
      self.names[item.name] = item
    end
  end
  return i
end

-- newDlgInfo(data): constructor; creates and returns a dialog info helper-object,
-- that facilitates the definition of dialog items,
-- and enables effortless access to these items "by name".
-- As a lightweight helper, it presents the info for later use in far.Dialog[Init].
-- data: table; the fields should correspond with parameters of identical names
-- as outlined in the far.DialogInit article
-- hh mk:@MSITStore:%FARHOME%\Encyclopedia\luafar_manual.chm::/378.html
-- The following parameters are not used: X1,Y1,X2,Y2
-- Instead, only the width should be explicitly provided;
-- the height is derived from the definitions of the items,
-- and the dialog is automaticaly centered.
-- Additional field:
-- * .width: number; w/o dialog margins
-- The returned object has the following methods: add, ln, params
-- And there is also a useful property:
-- names: table; as its fields contains items that have a name in their definitions.
local function newDlgInfo (data)
  data.Flags = data.Flags or 0
  assert(type(data.Flags)=="number")
  local function params (self) -- method; returns all arguments required for far.Dialog[Init]
    self.dlgHeight = self.y0*2 + self.y+1
    local item = self[1] -- 1st item
    if item[1]==F.DI_SINGLEBOX or item[1]==F.DI_DOUBLEBOX then
      item[5] = self.dlgHeight-self.y0 -- set Y2
    end
    return data.Guid,-1,-1, self.dlgWidth, self.dlgHeight, data.HelpTopic, self, data.Flags, data.DlgProc, data.Param
  end
  local function ln (self) -- method; "current" line++
    self.y = self.y+1
  end
  local self = {add=add, ln=ln, names={}, params=params }
  self.y = 0 -- offset - relative to y0
  local small = bit64.band(data.Flags, F.FDLG_SMALLDIALOG)~=0
  self.x0 = small and 0 or 3 -- working area start
  self.y0 = small and 0 or 1 --
  self.small = small
  self.width = assert(data.width, "width is required")
  self.dlgWidth = self.width + self.x0*2 -- width + margins
  return self
end
--> end of Dlg helper <--

--local Y1, X2 = 2,3                   -- coords indices
--local SELECTED, FLAGS, DATA = 6,9,10 -- tFarDialogItem indices

if _cmdline=="" then
  print "Dialog helper facilitating Items array definitions"
  print "(more detailed info in comments)"
  return
else -- export
  return newDlgInfo
end
