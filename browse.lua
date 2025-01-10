local browse
local success, le = pcall(require,"le")
if success then
  browse = le
else
  browse = function (t,title) -- very minimal stub
    local v = sh.dump(t)
    if select(2, string.gsub(v, "\n", "\n"))<Far.Height then
      far.Message(v, title, nil, "l")
    else
      far.Show(v)
    end
  end
end

local function pack (...) return {n=select("#", ...), ...} end
if _cmdline=="" then
  print "Allows to browse passed expression (e.g. table) in dialog"
  print "Usage: browse lua_expression"
  print "Export: sh.browse(table[,titlestr])"
  return
elseif _cmdline then
  local ret = pack(sh.eval(_cmdline))
  browse(ret[1], ret[2] or "")
  return unpack(ret, 1, ret.n)
else -- export
  return browse
end
