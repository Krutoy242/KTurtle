-- ********************************************************************************** --
-- **   Krutoy Turtle Wrapper                                                      ** --
-- **   ----------------------------------------------------                       ** --
-- **                                                                              ** --
-- **   Wrap standart turtle functions but monitoring position and orientation     ** --
-- **   To get turtle pos and orient use Turtle.pos and Turtle.orient              ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- Enumeration to store names for the 6 directions
local way = {
  FORWARD=0, 
  RIGHT  =1, 
  BACK   =2, 
  LEFT   =3, 
  UP     =4, 
  DOWN   =5
}
  
local maxActAttempts = 50
local alterAttempts   = 30
local indicateTroubleInAttempts = 40

-- Global Turtle variable
Turtle = {}
Turtle.__index = Turtle
math.randomseed(os.time())

-- Variables to store the current location and orientation of the turtle. x is right, left, z is up, down and
-- y is forward, back with relation to the starting orientation. 
Turtle.orient = way.FORWARD

Turtle.pos = vec3() -- Start Pos is 0,0,0
Turtle.beacons  = {}       -- User-made points to route
Turtle.oneWay   = nil      -- An 3d array of points where we cant move some special ways
Turtle.safeZone = nil      -- An 3d array of "safe" places, where we cant go with pickaxe
Turtle.alterZone= nil      -- 

local surround = {
[way.FORWARD] = vec3( 0, 1, 0),
[way.RIGHT]   = vec3( 1, 0, 0),
[way.BACK]    = vec3( 0,-1, 0),
[way.LEFT]    = vec3(-1, 0, 0),
[way.UP]      = vec3( 0, 0, 1),
[way.DOWN]    = vec3( 0, 0,-1)
}

local trtlOperationBySide = {
[way.FORWARD] = {turtle.forward, turtle.detect,     turtle.dig,     turtle.attack,     turtle.compare,     turtle.suck,     turtle.place},
[way.UP]      = {turtle.up,      turtle.detectUp,   turtle.digUp,   turtle.attackUp,   turtle.compareUp,   turtle.suckUp,   turtle.placeUp},
[way.DOWN]    = {turtle.down,    turtle.detectDown, turtle.digDown, turtle.attackDown, turtle.compareDown, turtle.suckDown, turtle.placeDown}
}

-- Call function only if it is function
local function safeCall(fnc, ...)
  if type(fnc)=='function' then fnc(...) end
end

-- Help function
local function addZoneInArray(arr, val, ...)
  local args = {...}
  local x1,y1,z1,x2,y2,z2
  -- Overload to working with vectors
  if type(args[1]) == 'table' and type(args[2]) == 'table' then
    x1,y1,z1,x2,y2,z2 = args[1]:unpack(), args[2]:unpack()
  else
    x1,y1,z1,x2,y2,z2 = ...
  end
  assert(x1 and y1 and z1 and x2 and y2 and z2, 'Wrong Turtle.addZone params')


  local sortFnc = function(n1,n2) if n2<n1 then return n2,n1 else return n1,n2 end end  
  x1,x2=sortFnc(x1,x2); y1,y2=sortFnc(y1,y2); z1,z2=sortFnc(z1,z2);
  
  for _z=0, z2-z1 do
    for _y=0, y2-y1 do
      for _x=0, x2-x1 do
        arr[z1+_z]        = arr[z1+_z]        or {}
        arr[z1+_z][y1+_y] = arr[z1+_z][y1+_y] or {}
        
        arr[z1+_z][y1+_y][x1+_x] = val
      end
    end
  end
end


local function getValueFrom3dArray(arr, vec)
  if arr == nil then return nil end
  if arr[vec.z] == nil then return nil end
  if arr[vec.z][vec.y] == nil then return nil end
  if arr[vec.z][vec.y][vec.x] == nil then return nil end
  return arr[vec.z][vec.y][vec.x]
end

-- ********************************************************************************** --
-- Add sector when we cant move in determined way
-- ********************************************************************************** --
function Turtle.addForbiddenWayZone(_way, _alter, ...)
  Turtle.oneWay = Turtle.oneWay or {}
  addZoneInArray(Turtle.oneWay, {_way, _alter}, ...)
end

-- ********************************************************************************** --
-- Add sector when we cant crushing blocks with pickaxe
-- ********************************************************************************** --
function Turtle.addSafeZone(...)
  Turtle.safeZone = Turtle.safeZone or {}
  addZoneInArray(Turtle.safeZone, true, ...)
end

-- ********************************************************************************** --
-- 
-- ********************************************************************************** --
function Turtle.addAlterZone(_alter, ...)
  Turtle.alterZone = Turtle.alterZone or {}
  addZoneInArray(Turtle.alterZone, _alter, ...)
end


-- ********************************************************************************** --
-- Sets the turtle to a specific orientation, irrespective of its current orientation
-- ********************************************************************************** --
function Turtle.setOrient(newOrient)

  -- Already turned
  if (Turtle.orient == newOrient) then return true end


  -- Wrong parameters - we cant turn up or down
  if newOrient < 0 or newOrient > way.LEFT then
    error("Invalid newOrient in Turtle.setOrient function")
    return false
  end
  
  local turn = Turtle.orient - newOrient
  local turnFnc
  
  if turn==1 or turn==-3 then
    turnFnc = turtle.turnLeft
  else
    turnFnc = turtle.turnRight
  end
  
  turn = math.abs(turn)
  if(turn==3) then turn=1 end

  for i=1, turn do turnFnc() end
  Turtle.orient = newOrient
  
  return true
end

-- ********************************************************************************** --
-- 
-- ********************************************************************************** --
function Turtle.turnRight()
  turtle.turnRight()
  Turtle.orient = (Turtle.orient + 1)%4
  return true
end
function Turtle.turnLeft()
  turtle.turnLeft()
  Turtle.orient = (Turtle.orient + 3)%4
  return true
end

--===========================================================
-- Dig, depending on direction
--===========================================================
local digFncArr = {[way.FORWARD]=turtle.dig, [way.DOWN]=turtle.digDown, [way.UP]=turtle.digUp}
function Turtle.dig(direction)
  direction = direction or way.FORWARD -- Optional param
  assert(direction == way.DOWN or direction == way.UP or direction == way.FORWARD, 'Wrong params in Turtle.dig()')
    
  return digFncArr[direction]()
end
 
-- ********************************************************************************** --
-- Generic function to move the Turtle (pushing through any gravel or other
-- things such as mobs that might get in the way).
--
-- The only thing that should stop the turtle moving is bedrock. Where this is
-- found, the function will return after 15 seconds returning false
-- ********************************************************************************** --
function Turtle.move(direction, doNotTurnBack)
  local straightDirection = (direction == way.FORWARD or direction == way.UP or direction == way.DOWN)

  local isReceding = (direction == way.BACK)
  local tmpDir = straightDirection and direction or way.FORWARD
  local moveFn, detectFn, digFn, attackFn = unpack(trtlOperationBySide[tmpDir])
  
  local destination = Turtle.getRelativeCoord(direction)
  local newX, newY, newZ = destination:unpack()
  
  -- Flag to determine whether digging has been tried yet. If it has
  -- then pause briefly before digging again to allow sand or gravel to drop
  local attempt = 0
 
  -- Raise event if we try to move
  safeCall(Turtle.onMoveAttempt, attempt, newX, newY, newZ, direction)
  
  -- Check if this move is forbidden. In this case change move to other way
  local forbid = getValueFrom3dArray(Turtle.oneWay, Turtle.pos)
  if forbid ~= nil and forbid[1] == Turtle.getIrrespectiveOrient(direction) then
    return Turtle.move(Turtle.getRelativeOrient(forbid[2]), doNotTurnBack)
  end
  
  -- Speciall kind of sides
  local oldOrient= Turtle.orient
  if not straightDirection then
    if direction == way.RIGHT then Turtle.turnRight() end
    if direction == way.LEFT  then Turtle.turnLeft()  end
    direction = way.FORWARD
  end

  local moveSuccess = false
  if isReceding then moveSuccess = turtle.back()
  else moveSuccess = moveFn() end
 

  -- Check if we want to move into safe zone. In this case dig will be turned off
  local safe = getValueFrom3dArray(Turtle.safeZone, destination)
 
  -- Loop until we've successfully moved
  while not moveSuccess do
  
    -- We had too many attempts. Now we can only make error
    if attempt >= maxActAttempts then
      safeCall(Turtle.onMoveFailure, newX, newY, newZ)
      return false
    end
    
    -- Check if this move is forbidden. In this case change move to other way
    if attempt >= alterAttempts then
      local alternative = getValueFrom3dArray(Turtle.alterZone, Turtle.pos)
      if alternative ~= nil and alternative ~= Turtle.getIrrespectiveOrient(direction) then
        return Turtle.move(Turtle.getRelativeOrient(alternative), doNotTurnBack)
      end
    end
    
    -- Show that we are stuked a bit. Turn 360*
    if attempt>1 and attempt % indicateTroubleInAttempts == 0 then
      for i=1,4 do Turtle.turnRight() end
    end
    
    -- Turn face to distraction to dig it if we are go backwards
    if isReceding then Turtle.turnRight(); Turtle.turnRight(); direction = way.FORWARD end
 
    -- If there is a block in front, dig it
    if not (safe==true) then
      if detectFn() == true then
        digFn()
      else
        -- Am being stopped from moving by a mob, attack it
        attackFn()
      end
      
    end

    -- Raise event if we try to move
    safeCall(Turtle.onMoveAttempt, attempt, newX, newY, newZ, direction)
      
    -- Try the move again
    moveSuccess = moveFn()
    
    attempt = attempt + 1
    
    -- Random sleep between attempts
    if not moveSuccess then sleep(math.random()/10+0.1) end
  end
  
  Turtle.pos = destination
  
  -- Turn turtle back on origin orient
  if not straightDirection and doNotTurnBack ~= true then
    Turtle.setOrient(oldOrient)
  end
 
  -- Return the move success
  return moveSuccess
end

function Turtle.forward() return Turtle.move(way.FORWARD) end
function Turtle.up()      return Turtle.move(way.UP) end
function Turtle.down()    return Turtle.move(way.DOWN) end
function Turtle.back(doNotTurnBack)  return Turtle.move(way.BACK,  doNotTurnBack) end
function Turtle.left(doNotTurnBack)  return Turtle.move(way.LEFT,  doNotTurnBack) end
function Turtle.right(doNotTurnBack) return Turtle.move(way.RIGHT, doNotTurnBack) end

-- ********************************************************************************** --
-- Get relativety position from direction of turtle
-- ********************************************************************************** --
function Turtle.getRelativeCoord(direct)
  -- Return direction with displace
  return Turtle.pos + surround[Turtle.getIrrespectiveOrient(direct)]
end

-- ********************************************************************************** --
-- Get relativety position from direction of turtle
-- ********************************************************************************** --
function Turtle.getIrrespectiveOrient(direct) 
  local irrespectiveOrient -- New irrespective orientation to world
  
  if direct == way.UP or direct == way.DOWN then
    irrespectiveOrient = direct
  else
    irrespectiveOrient = (Turtle.orient + direct)%4
  end
  return irrespectiveOrient
end

function Turtle.getRelativeOrient(direct) 
  local relativeOrient
  if direct == way.UP or direct == way.DOWN then
    return(direct)
  else
    return (Turtle.orient + 4 - direct)%4
  end
end


 
--===========================================================
-- Find path to coordinates, avoid block listed cells
-- Using A* algorithm http://pastebin.com/CHCB8nDz
--===========================================================
function Turtle.pathTo(world, ...)
  local args = {...}
  local x,y,z

  -- Overload to working with vectors
  if type(args[1]) == 'table' then
    x,y,z = args[1]:unpack()
  else
    x,y,z = ...
  end
  assert(x and y and z, 'Wrong Turtle.pathTo() params')
  
  -- Already here!
  if Turtle.pos.x==x and Turtle.pos.y==y and Turtle.pos.z==z then return true end

  -- Get first crumb of path
  local crumb = AStarFindPath(world, Turtle.pos, vec3(x,y,z))
  
  if crumb then
    -- Run over all crumbs 
    while crumb.next ~= nil do
      crumb = crumb.next
      Turtle.goTo(crumb.pos)
    end
  else
    -- Path can be found. Move straight
    Turtle.goTo(x,y,z)
  end
  
end

--===========================================================
-- Move turtle on needed position
-- Simple move by x, then y, then z 
-- args can be vector or three parameters x,y,z
--===========================================================
function Turtle.goTo(...)
  local args = {...}
  local x,y,z

  -- Overload to working with vectors
  if type(args[1]) == 'table' then
    x,y,z = args[1]:unpack()
  else
    x,y,z = ...
  end
  assert(x and y and z, 'Wrong Turtle.goTo() params')

  local targetPos = vec3(x,y,z)
  local targetVec = targetPos - Turtle.pos
  
  -- We need additional loop for cases of one way roads
  while not targetPos == Turtle.pos do
  
    -- X
    if (targetVec.x<0 and Turtle.orient==way.RIGHT)   or
       (targetVec.x>0 and Turtle.orient==way.LEFT)    then
       while Turtle.pos.x ~= x do
         Turtle.back(true)
       end
    end
    
    while (x<Turtle.pos.x) do
      Turtle.setOrient(way.LEFT)
      Turtle.forward()
    end
    while (x>Turtle.pos.x) do
      Turtle.setOrient(way.RIGHT)
      Turtle.forward()
    end
    
    
    -- Y
    if(targetVec.y<0 and Turtle.orient==way.FORWARD) or
      (targetVec.y>0 and Turtle.orient==way.BACK)    then
       while Turtle.pos.y ~= y do
         Turtle.back(true)
       end
    end
    
    while (y<Turtle.pos.y) do
      Turtle.setOrient(way.BACK)
      Turtle.forward()
    end
    while (y>Turtle.pos.y) do
      Turtle.setOrient(way.FORWARD)
      Turtle.forward()
    end
    
    
    -- Z
    while (z<Turtle.pos.z) do
      Turtle.down()
    end
    while (z>Turtle.pos.z) do
      Turtle.up()
    end
  end
  
  return true
end

-- ********************************************************************************** --
-- Add point for easy acces
-- ********************************************************************************** --
function Turtle.addBeacon(beaconName, _x,_y,_z)
  Turtle.beacons[beaconName] = vec3(_x,_y,_z)
end

-- ********************************************************************************** --
-- Use saved beacons to go
-- ********************************************************************************** --
function Turtle.goToBeacon(beaconName)
  if not Turtle.beacons[beaconName] then return false end
  return Turtle.goTo(Turtle.beacons[beaconName])
end

-- ********************************************************************************** --
-- Select non-empty slot
-- ********************************************************************************** --
function Turtle.selectNonEmptySlot()
  for i=1, 16 do
    if( turtle.getItemCount(i) > 0) then
      turtle.select(i)
      return true
    end
  end
  return false
end

-- ********************************************************************************** --
-- Place item. Check if item already placed.
-- ********************************************************************************** --
function Turtle.place(itemSlot, direction)
  assert(direction==way.FORWARD or direction==way.UP or direction==way.DOWN, 'Wrong Turtle.place() params')
  
  local _, detectFnc, _, attackFnc, compareFnc, _, placeFnc = unpack(trtlOperationBySide[direction])
  
  -- slotsPattern is array of 16 nubbers that represent
  -- what kind of blocks lying in what kind of
  if(itemSlot == nil) then
    Turtle.selectNonEmptySlot()
  else
    turtle.select(itemSlot)
  end
  
  local placeSucces = false
  local digCount = 0
  local maxDigCount = 20
  local attempt = 0

  
  -- Check if there is already item  then try to place
  placeSucces = placeFnc()
  
  if((not placeSucces) and detectFnc()) then
    if(compareFnc()) then
      -- Item that we must set already here
      return true
    else
      -- There is something else. Dig/Attack and place item
      Turtle.dig(direction)
      digCount = digCount + 1
    end
  end
  
  -- Now try to place item until item will placed
  while ((placeSucces == false) and (digCount < maxDigCount)) and attempt < maxActAttempts do
    if (detectFnc()) then
      if(digCount > 0) then
        sleep(0.4)
      end
      Turtle.dig(direction)
      digCount = digCount + 1
    else
       -- Am being stopped from moving by a mob, attack it
       attackFnc()
    end
    -- Try the place again
    placeSucces = placeFnc()
    
    attempt = attempt + 1
  end
  
  return placeSucces
end
