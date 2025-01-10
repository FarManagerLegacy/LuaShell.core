if _cmdline then
  print "This script is used to preconfigure environment before evaluating expression in Execute Dialog"
  print "and `eval.lua` script"
  print "Function: combine functions from several sources"
  print "          and provide them to global namespace"
  return
end

local SimSUenv = {}
sh("_eval_SimSU", SimSUenv)()

local __index = {
  math,
  SimSUenv,
  --https://forum.farmanager.com/viewtopic.php?t=10574
  pcall(require, "shmuz.fl_calc") and require "shmuz.fl_calc" or nil
}

function sh.autoload (name)
  for _,t in ipairs(__index) do
    if t[name]~=nil then return t[name] end
  end
  -- return nil -- << to prevent scripts autoload for unknown identifiers
end

