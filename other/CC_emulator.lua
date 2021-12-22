
loadfile('src/60_Thread.lua')()
loadfile('src/30_Swarm.lua')()
loadfile('src/20_KUI.lua')()
loadfile('src/10_KTurtle.lua')()
loadfile('src/50_TableToString.lua')()

thread.create = function()end
KUI.navigate  = function()end
KUI.drawText  = function()end
KUI.drawTextPanel= function()end
KUI.setWindow= function()end

local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

loadfile('other/rom/apis/vector')()
read = function() end

fs = {}
fs.list = function() return {} end


local tbl = {
['getSize'] = function() return 50,21 end
}
term = setmetatable({}, {__index = function (t, k)
  if tbl[k] == nil then return function()end end
  return tbl[k]
end})



local tbl = {
['getSides'] = function() return {'left', 'right'} end
}
rs = setmetatable({}, {__index = function (t, k)
  return tbl[k]
end})


local tbl = {
['isOpen'] = function() return false end,
['open']   = function() return true end
}
rednet = setmetatable({}, {__index = function (t, k)
  if tbl[k] == nil then return function()end end
  return tbl[k]
end})


local tbl = {
['getType'] = function() return 'modem' end
}
peripheral = setmetatable({}, {__index = function (t, k)
  return tbl[k]
end})


local tbl = {
['pullEvent'] = function() return nil end,
['time'] = function() return 100 end,
['getComputerLabel'] = function() return "label1" end
}
os = setmetatable({}, {__index = function (t, k)
  return tbl[k]
end})



local tbl = {
['getFuelLevel'] = function() return 3333333 end
}
turtle = setmetatable({}, {__index = function (t, k)
  if tbl[k] == nil then return function() return true end end
  return tbl[k]
end})