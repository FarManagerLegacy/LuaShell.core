-- from Common_Calculator.lua
-- https://forum.farmanager.com/viewtopic.php?t=7075

if _cmdline then
  print "This script is used to preconfigure environment before evaluating expression in Execute Dialog"
  print "Source: Common_Calculator.lua by SimSU"
  return
end

-- luacheck: allow defined top
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function str2tab(str) -- Преобразование строки в таблицу
  str=str or ""
  local a={}
  for val in str:gmatch("%S+") do
    a[#a+1]=val
  end
  return a
end

function tabnum(tab) -- Преобразование таблицы в таблицу чисел, нечисловые значения в результат не попадают
  tab=tab or {}
  local j,a=1,{}
  for i=1,#tab do
    a[j]=tonumber(tab[i])
    if a[j] then j=j+1 end
  end
  return a
end

function tabstr(tab) -- Преобразование таблицы в таблицу строк, незакавыченные значения в результат не попадают
  tab=tab or {}
  local j,a=1,{}
  for i=1,#tab do
    a[j]=tab[i]:match("'.-'") or tab[i]:match('".-"')
    if a[j] then j=j+1 end
  end
  return a
end

function tab2str(tab,sep) -- Преобразование таблицы в строку
  tab=tab or {}
  sep=sep or "\t"
  return table.concat(tab,sep)
end

function count(str) -- Определение количества всех элементов в таблице, чисел и строк
  str=str or ""
  local tab=str2tab(str)
  return #tab,#tabnum(tab),#tabstr(tab)
end

function sumnum(tab) -- сумма элементов в таблице
  local s=0
  for i=1,#tab do
    s=s+tab[i]
  end
  return s
end

function mean(tab) -- среднее
  return tab and #tab>0 and sumnum(tab)/#tab or math.huge
end

function sqrnum(tab) -- массив квадратов элементов массива
  local a={}
  for i=1,#tab do
    a[i]=tab[i]*tab[i]
  end
  return a
end

function addnum(tab,num) -- прибавление числа ко всем элементам массива
  tab=tab or {}
  num=num or 0
  local a={}
  for i=1,#tab do
    a[i]=tab[i]+num
  end
  return a
end

function multnum(tab,num) -- умножение массива на число
  tab=tab or {}
  num=num or 0
  local a={}
  for i=1,#tab do
    a[i]=tab[i]*num
  end
  return a
end

function sigma(tab)  -- СКО
  tab=tab or {}
  return sumnum(sqrnum(addnum(tab,-mean(tab))))/(#tab-1)
end
