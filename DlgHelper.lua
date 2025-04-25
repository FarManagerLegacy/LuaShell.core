--> begin of Dlg helper <-- v0.2
-- Obj = newDlgInfo(data);
-- Creates a new dialog information object.
--
-- Argument:
-- * data: table with the following fields:
--   - width: number - the width of the dialog's client area, excluding any margins and frames.
--   - Guid, HelpTopic, Flags, DlgProc, Param - optional fields, corresponding to parameters
--     documented in the LuaFAR manual: mk:@MSITStore:%FARHOME%\Encyclopedia\luafar_manual.chm::/20.html
--   Note: X1,Y1,X2,Y2 and Items should not be provided in the `data` table,
--   as dialog Items (controls) are intended to be added sequentially using the Obj:add method (see below),
--   and the dialog's overall coordinates are evaluated implicitly,
--   based on the added items and the specified `width`.
--
-- Returns:
-- * Obj: table with the following methods: add, ln, params (see detailed descriptions below).
--   Once all items have been added, the dialog itself can be created with the standard call:
--   far.Dialog(Obj:params()).
--
local function newDlgInfo (data)
  local F = far.Flags --luacheck: ignore 431/F
  data.Flags = data.Flags or 0
  assert(type(data.Flags)=="number")
  -- consts:
  local TYPE, X1, Y1, X2, Y2, FLAGS, DATA = 1,2,3,4,5,9,10 -- indices in dlg item's arr
  local x1,y1,x2,y2 = 1,2,3,4 -- indices in coords arr
  -- privat props:
  local small = bit64.band(data.Flags, F.FDLG_SMALLDIALOG)~=0
  local __x0 = small and 0 or 3 -- client area start
  local __y0 = small and 0 or 1 --
  local __y = 0 -- offset - relative to y0
  local __width = assert(data.width, "width is required")
  local Obj = {}
  --Obj.small = small
  local function norm (arg, base, align)
    if not arg or arg==0 then
      return base
    elseif type(arg)=="string" then
      return base + tonumber(arg)
    end
    return base + arg + (arg<0 and align or 0)
  end
  -- :add{args...} - method, adds a new dlg item (control) to the dialog layout.
  --
  -- Arguments are passed in a table;
  -- unlike LuaFAR's standard [tFarDialogItem](mk:@MSITStore:%FARHOME%\Encyclopedia\luafar_manual.chm::/295.html),
  -- arguments in the table can be passed not only positionally, but also as named fields;
  -- The coords (X1,Y1,X2,Y2) should be specified in a separate array table and normally in simplified form,
  -- as there is special processing to deduce omitted values from the context (see below).
  -- * positional args are all optional: Type, Data (text), coords (arr[4]), Flags, Selected/ListItems
  -- * named args: name, History, Mask, MaxLength, UserData + all names of positional args.
  --   See detailed descriptions at https://api.farmanager.com/ru/structures/fardialogitem.html
  -- * coords: table (optional), arr[x1,y1,x2,y2] (each element is also optional),
  --   can also contain fields .interval and .width (see below)
  --   - x/y are handled in a special way independently of the presence of dialog margins and frames,
  --     and should be specified relative to the dialog's client area, based on the initial `width`.
  --   - if x1/x2 is a negative number, it's treated as an offset from the right edge;
  --     To use a literal negative value, pass it as a string (e.g. "-1").
  --   - x1 is optional and if omitted, it is calculated automatically based on the coords of the previous item on the same line,
  --     to specify the horizontal gap explicitly (instead of the default 1), provide the .interval field.
  --   - x2 is optional and defaults to x1;
  --     alternatively, the .width field can be specified to calculate x2.
  --   - y1/y2 are optional and default to the "current line", determined by the last call to the :ln() method.
  -- * name: if provided, the item becomes accessible as Obj[name].
  --   The names are checked for uniqueness, and certain identifiers are reserved
  --   (currently Obj's methods: add, ln, params).
  -- * any other provided fields are stored directly on the item object for custom use.
  --
  -- Returns:
  -- The index of the newly added item within Obj's array part;
  -- it is also stored in the item's .idx field.
  function Obj:add (item)
    item[6] = item[5] or item.Selected or item.ListItems or 0
    item[7] = item.History
    item[8] = item.Mask
    item[FLAGS] = item[4] or item.Flags
    item[DATA] = item[2] or item.Data
    item[11] = item.MaxLength
    item[12] = item.UserData
    local c = item[3] or item.coords or {}
    local prev = self[#self]
    if not c[x1] and not c[y1] and prev and prev[Y1]==__y0+__y and prev[DATA] then -- same line
      local prevX1,prevX2 = prev[X1], prev[X2]
      if prevX2<=prevX1 then
        local len = prev[DATA]:len()
        if bit64.band(item[FLAGS], F.DIF_LISTNOAMPERSAND)==0 then
          prev[DATA]:gsub("&&?", function() len = len-1 end)
        end
        if prev[TYPE]==F.DI_BUTTON then
          if bit64.band(item[FLAGS], F.DIF_NOBRACKETS)==0 then
            len = len+4
          end
        elseif prev[TYPE]==F.DI_CHECKBOX or prev[TYPE]==F.DI_RADIOBUTTON then
          len = len+4
        end
        prevX2 = prevX1+len-1
      end
      c[x1] = prevX2-__x0+1+(c.interval or 1)
    end
    local coords = {}
    coords[x1] = norm(c[x1], __x0, __width)
    coords[y1] = norm(c[y1], __y0+__y)
    if not c[x2] then
      coords[x2] = c.width and coords[x1]+c.width-1 or coords[x1]
    else
      coords[x2] = norm(c[x2], __x0, __width)
    end
    coords[y2] = not c[y2] and coords[y1] -- y2==y1
             or norm(c[y2], __y0+__y)
    item[TYPE] = item[TYPE] or item.Type
    for i=1,4 do item[i+1] = coords[i] end
    local i = #self+1; item.idx = i; self[i] = item;
    if i==1 and (item[TYPE]==F.DI_SINGLEBOX or item[TYPE]==F.DI_DOUBLEBOX) then
      __x0, __y0, __width = __x0+2, __y0+1, __width-2*2 -- accomodate "working area" params
    end
    if item.name then
      if self[item.name] then
        far.Message("Duplicated item name: "..item.name, "Error in config", nil ,"lw")
      else
        self[item.name] = item
      end
    end
    return i
  end

  -- :ln() - method; increments the internal 'current line' counter.
  -- Note: Subsequent calls to `:add()` without an explicit `y` coordinate
  --       will place items on the same current line.
  function Obj.ln ()
    __y = __y+1
  end

  local dlgWidth = __width + __x0*2 -- width + margins
  -- :params() - method; calculates the final dialog coordinates,
  -- and returns all arguments required for the subsequent far.Dialog[Init] call.
  function Obj:params ()
    local dlgHeight = __y0*2 + __y+1
    local item = self[1] -- 1st item
    if item[TYPE]==F.DI_SINGLEBOX or item[TYPE]==F.DI_DOUBLEBOX then
      item[Y2] = dlgHeight-__y0
    end
    return data.Guid,-1,-1, dlgWidth, dlgHeight, data.HelpTopic, self, data.Flags, data.DlgProc, data.Param
  end
  return Obj
end
--> end of Dlg helper <--

-- coords indices:
--local Y1, X2 = 2,3
-- tFarDialogItem indices:
--local SELECTED, HISTORY, FLAGS, DATA = 6,7,9,10

if _cmdline=="" then
  print "Dialog helper facilitating Items array definitions"
  print "(more detailed info in comments)"
  return
else -- export
  return newDlgInfo
end
