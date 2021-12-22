-- ********************************************************************************** --
-- **                                                                              ** --
-- **   A-Star algorithm for 3d dimensional volume                                 ** --
-- **                                                                              ** --
-- **   http://en.wikipedia.org/wiki/A*_search_algorithm                           ** --
-- **   ----------------------------------------------------                       ** --
-- **                                                                              ** --
-- **   Developed to use in program "KrutoyTurtle"                                 ** --
-- **   http://computercraft.ru/topic/48-stroitelnaia-sistema-krutoyturtle/        ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- Redefine global function for faster acces
local abs,pairs,floor,time,insert,remove = math.abs,pairs,math.floor,os.time,table.insert,table.remove

-- Heuristic estimate.
local function heuristic_cost_estimate(p1,p2)
  return abs(p1.x-p2.x) + abs(p1.y-p2.y) + abs(p1.z-p2.z)
end

-- ********************************************************************************** --
-- **                         Utils                                                ** --
-- ********************************************************************************** --

-- 3d array metatable
-- Use arr3d() as constructor, arr(x,y,z) as acces and arr:set(x,y,z,v) as set value
if not arr3d then arr3d = function() return setmetatable({
  set = function(t,x,y,z,v)
    t[z]    = t[z]    or {}
    t[z][y] = t[z][y] or {}
    t[z][y][x] = v
  end,
  setVolume = function(t, x1,y1,z1,x2,y2,z2, v)
    for z=z1, z2 do
      for y=y1, y2 do
        for x=x1, x2 do
          t:set(x,y,z, v)
        end
      end
    end
  end
  }, { __call = function(t, x, y, z)
    if not t[z] or not t[z][y] then return nil end
    return t[z][y][x]
  end
})end end


-- Checking time for avoid yeld exception
local chtime
local function checktime()
  -- os.queueEvent("")
  -- coroutine.yield()

  if not chtime then chtime=time() end
  local ntime=time()
  if ntime-chtime>0.05 or ntime-chtime<0  then
    sleep(0)
    chtime=ntime
  end
end

-- ********************************************************************************** --
-- **                            BreadCrumb                                        ** --
-- ********************************************************************************** --

local BreadCrumb = {}
BreadCrumb.__index = BreadCrumb

function BreadCrumb.new(x,y,z, parent)
  local self = setmetatable({}, BreadCrumb)
  self.pos = {x=x,y=y,z=z}
  self.next = parent
  self.cost = math.huge
  self.onClosedList = false
  self.onOpenList = false
  return self
end

function BreadCrumb:Equals(b)
    return b.pos.x == self.pos.x and b.pos.y == self.pos.y and b.pos.z == self.pos.z
end

-- ********************************************************************************** --
-- **                          Path Finder                                         ** --
-- ********************************************************************************** --

-- Neigtbours of current point
local surrounding = {
  {x=0,y=0,z=-1}, {x=0,y=0,z= 1}, {x=0,y=-1,z=0}, {x=0,y= 1,z=0}, {x=-1,y=0,z=0}, {x=1, y=0,z=0},
}


-- Method that switfly finds the best path from p_start to end.
-- The starting breadcrumb traversable via .next to the end or nil if there is no path
function AStarFindPath(world, p_start, p_end)
    -- note we just flip p_start and end here so you don't have to.
   p_end, p_start = p_start, p_end

  -- Destination point is bloked
  if world(p_start.x, p_start.y, p_start.z) then return end

  local openList = {}
  local brWorld  = arr3d()


  local current= BreadCrumb.new(p_start.x,p_start.y,p_start.z)
  current.cost = heuristic_cost_estimate(current.pos,p_end)

  local finish = BreadCrumb.new(p_end.x,p_end.y,p_end.z)
  brWorld:set(current.pos.x,current.pos.y,current.pos.z,current)
  insert(openList,current)


  while #openList > 0 do
    --Find best item and switch it to the 'closedList'
    current = remove(openList)
    current.onClosedList = true

    --Find neighbours
    for k,v in pairs(surrounding) do
      local tmpX,tmpY,tmpZ = current.pos.x + v.x, current.pos.y + v.y, current.pos.z + v.z
      if not world(tmpX,tmpY,tmpZ) then
        --Check if we've already examined a neighbour, if not create a new node for it.
        local node
        if brWorld(tmpX,tmpY,tmpZ) == nil then
          node = BreadCrumb.new(tmpX,tmpY,tmpZ)
          brWorld:set(tmpX,tmpY,tmpZ,node)
        else
          node = brWorld(tmpX,tmpY,tmpZ)
        end

        --If the node is not on the 'closedList' check it's new score, keep the best
        if node.onClosedList == false then
          local cost = heuristic_cost_estimate(node.pos,p_end)

          if cost < node.cost then
            node.cost = cost
            node.next = current
          end

          --If the node wasn't on the openList yet, add it
          if node.onOpenList == false then
            --Check to see if we're done
            if node:Equals(finish) == true then
              node.next = current
              return node
            end
            node.onOpenList = true

            -- Sort and add to open list
            local pos = #openList
            while pos > 0 and openList[pos].cost <= node.cost do
                pos = pos - 1
            end
            insert(openList,pos+1,node)
          end
        end
      end
    end
    checktime() -- Check yelding time for computerCraft
  end

  return nil --no path found
end


-- ********************************************************************************** --
-- **                              Usage                                           ** --
-- ********************************************************************************** --


--[[
-- Create new world as 3d array
local world = arr3d()

-- Block a cell, make it impassable. Indexes from [0]
-- Indexes is [x][y][z]
--world:setVolume(0,0,0,9,9,0,true)
--world:setVolume(0,0,9,9,9,9,true)

--world:setVolume(0,0,0,9,0,9,true)
--world:setVolume(0,9,0,9,9,9,true)

--world:setVolume(0,0,0,0,9,9,true)
--world:setVolume(9,0,0,9,9,9,true)
world:set(1,3,1,true)
world:set(1,7,1,true)
world:setVolume(-1,5,-1,3,5,3,true)
world:set(1,5,1,nil)


local p_start = {x=1,y=9,z=1} -- Start point.
local p_end   = {x=1,y=1,z=1} -- End point

-- Main path find function
-- Return the first bread crumb of path
local crumb = AStarFindPath(world, p_start, p_end)

if crumb == nil then
  print('Path not found')
else
  io.write('['.. crumb.pos.x..","..crumb.pos.y..","..crumb.pos.z.."]->")

  -- BreadCrumbs is connected list. To get next point in path use crumb.next
  while crumb.next ~= nil do
    crumb = crumb.next
    io.write('['.. crumb.pos.x..","..crumb.pos.y..","..crumb.pos.z..(crumb.next and "]->" or "]"))
  end
end
--]]
