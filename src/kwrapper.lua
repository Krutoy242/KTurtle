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



local oppositeWay = {[0]=2,3,0,1,5,4}
  
local attemptsToAlternative = 5
local attemptsToFailure = 7
local attemptsToIndicate = 15

local dataFilePath = "Krutoy/location"

-- Global Turtle variable
Turtle = {}
Turtle.__index = Turtle
math.randomseed(os.time())

-- Variables to store the current location and orientation of the turtle. x is right, left, z is up, down and
-- y is forward, back with relation to the starting orientation. 
Turtle.orient = way.FORWARD

-- If turtle start moving in some direction, store it here
Turtle.moving = nil

Turtle.pos = vec3()        -- Start Pos is 0,0,0
Turtle.beacons  = {}       -- User-made points to route
Turtle.safe     = true     -- In this mode turtle will newer crush forbidden blocks
Turtle.oneWay   = arr3d()  -- An 3d array of points where we cant move some special ways
Turtle.safeZone = arr3d()  -- An 3d array of "safe" places, where we cant go with pickaxe
Turtle.alterZone= arr3d()  -- 
Turtle.world    = arr3d()  -- World of blocked positions for path finding

Turtle.lowFuelLevel = 300  -- Call onLowFuel function if above this 

local surround = {
[way.FORWARD] = vec3( 0, 1, 0),
[way.RIGHT]   = vec3( 1, 0, 0),
[way.BACK]    = vec3( 0,-1, 0),
[way.LEFT]    = vec3(-1, 0, 0),
[way.UP]      = vec3( 0, 0, 1),
[way.DOWN]    = vec3( 0, 0,-1)
}

local cc_sides = {
[way.FORWARD] = "front",
[way.RIGHT]   = "right",
[way.BACK]    = "back",
[way.LEFT]    = "left",
[way.UP]      = "top",
[way.DOWN]    = "bottom"
}

local trtlOperationBySide = {
[way.FORWARD] = {turtle.forward, turtle.detect,     turtle.dig,     turtle.attack,     turtle.compare,     turtle.suck,     turtle.place,     turtle.inspect},
[way.UP]      = {turtle.up,      turtle.detectUp,   turtle.digUp,   turtle.attackUp,   turtle.compareUp,   turtle.suckUp,   turtle.placeUp,   turtle.inspectUp},
[way.DOWN]    = {turtle.down,    turtle.detectDown, turtle.digDown, turtle.attackDown, turtle.compareDown, turtle.suckDown, turtle.placeDown, turtle.inspectDown}
}

local thrash = {"minecraft:stone","minecraft:cobblestone","minecraft:dirt","minecraft:gravel","minecraft:grass","minecraft:sand"}

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
        arr:set(x1+_x,y1+_y,z1+_z,val)
      end
    end
  end
end


-- Saving location and stats to file
function Turtle.removeData()
  fs.delete(dataFilePath)
  
  Turtle.pos    = vec3()
  Turtle.orient = way.FORWARD
  Turtle.moving = way.FORWARD
  Turtle.beacons= {}
end


-- Saving location and stats to file
function Turtle.saveData(movingDir)
  if movingDir then Turtle.moving = movingDir end
  
  local saveData = {
    x=Turtle.pos.x,
    y=Turtle.pos.y,
    z=Turtle.pos.z,
    orient=Turtle.orient,
    fuel=turtle.getFuelLevel(),
    moving=Turtle.moving,
    beacons=Turtle.beacons}
  local f = fs.open(dataFilePath, "w")
  f.write(table.toString(saveData))
  f.close()
end

-- Taken from
-- http://www.computercraft.info/forums2/index.php?/topic/19939
-- By Signify
function Turtle.loadData()
  --Checking for previous config...
  if fs.exists(dataFilePath) then
    local f = fs.open(dataFilePath, "r")
    local data = table.fromString(f.readAll())
    f.close()

    --Config found. Loading data
    --Checks to make sure turtle didn't move or do anything wonky after reboot
    local currentFuel = turtle.getFuelLevel()
    if data.fuel == currentFuel or data.fuel == currentFuel+1 then
      local oldState = {pos=Turtle.pos, orient=Turtle.orient}
      --Loading in the data since nothig bad happened
      Turtle.pos    = vec3(data.x, data.y, data.z)
      Turtle.orient = data.orient
      Turtle.moving = data.moving
      
      if data.fuel == currentFuel+1 then
        --Here, we've gotta fix a few things since the turtle did in fact, move
        Turtle.setPos(Turtle.getRelativeCoord(Turtle.moving))
      end
      
      -- Indicate that we are resuming
      if oldState.pos == Turtle.pos and Turtle.orient == oldState.orient then
        return false
      else
        Turtle.beacons = data.beacons
        for k,v in pairs(Turtle.beacons) do
          Turtle.beacons[k] = vec3(v)
        end
        
        return true
      end
    else
      --Looks like the fuel level changed by more than one. Wiping location knowledge
      Turtle.removeData()
    end
  end
  return false
end

-- ********************************************************************************** --
-- Add sector when we cant move in determined way
-- ********************************************************************************** --
function Turtle.addForbiddenWayZone(_way, _alter, ...)
  addZoneInArray(Turtle.oneWay, {_way, _alter}, ...)
end

-- ********************************************************************************** --
-- Add sector when we cant crushing blocks with pickaxe
-- ********************************************************************************** --
function Turtle.addSafeZone(...)
  addZoneInArray(Turtle.safeZone, true, ...)
end

-- ********************************************************************************** --
-- 
-- ********************************************************************************** --
function Turtle.addAlterZone(_alter, ...)
  addZoneInArray(Turtle.alterZone, _alter, ...)
end


-- ********************************************************************************** --
-- Sets the turtle coordinates
-- ********************************************************************************** --
function Turtle.setPos(...)
  local args = {...}
  local x,y,z

  -- Overload to working with vectors
  if type(args[1]) == 'table' then
    x,y,z = args[1]:unpack()
  else
    x,y,z = ...
  end
  assert(x and y and z, 'Wrong Turtle.setPos() params')
  
  Turtle.pos = vec3(x,y,z)
  Turtle.saveData()
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
    turnFnc = Turtle.turnLeft
  else
    turnFnc = Turtle.turnRight
  end
  
  turn = math.abs(turn)
  if(turn==3) then turn=1 end

  for i=1, turn do turnFnc() end
  
  return true
end

-- ********************************************************************************** --
-- 
-- ********************************************************************************** --
function Turtle.turnRight()
  turtle.turnRight()
  Turtle.orient = (Turtle.orient + 1)%4
  Turtle.saveData()
  return true
end
function Turtle.turnLeft()
  turtle.turnLeft()
  Turtle.orient = (Turtle.orient + 3)%4
  Turtle.saveData()
  return true
end

--===========================================================
-- Test name for thrashed ore
--===========================================================
function Turtle.isThrash(name)
  if type(name) == "string" then
    for i=1,#thrash do
      if thrash[i] == name then return true end
    end
  end
  return false 
end


--===========================================================
-- Determine when turtle have very low fuel
--===========================================================
function Turtle.isLowFuel()
  return  turtle.getFuelLevel() <= Turtle.lowFuelLevel
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

--===========================================================
-- Dig only ore
--===========================================================
function Turtle.mine(direction)
  direction = direction or way.FORWARD -- Optional param
  assert(direction == way.DOWN or direction == way.UP or direction == way.FORWARD, 'Wrong params in Turtle.mine()')
  
  local inspectFc = trtlOperationBySide[direction][8]
  local _,blockData = inspectFc()
  local blockName = blockData and blockData.name
  if Turtle.isThrash(blockName) then
    return false
  else
    return digFncArr[direction]()
  end
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
  local moveFn, detectFn, digFn, attackFn,_,_,_, inspectFn = unpack(trtlOperationBySide[tmpDir])

  
  local destination = Turtle.getRelativeCoord(direction)
  local newX, newY, newZ = destination:unpack()
  
  -- Low fuel event
  if Turtle.isLowFuel() then
    safeCall(Turtle.onLowFuel, newX, newY, newZ, direction)
  end
  
  -- Flag to determine whether digging has been tried yet. If it has
  -- then pause briefly before digging again to allow sand or gravel to drop
  local attempt = 0
 
  -- Raise event if we try to move
  safeCall(Turtle.onMove, attempt, newX, newY, newZ, direction)
  safeCall(Turtle.onMoveAttempt, attempt, newX, newY, newZ, direction)
  
  -- Check if this move is forbidden. In this case change move to other way
  local forbid = Turtle.oneWay(Turtle.pos:unpack())
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
  
  
  local moveWithSave = function(mFn)
    Turtle.saveData(direction)
    return mFn()
  end
  
  
  local moveSuccess = false
  if isReceding then
    moveSuccess = moveWithSave(turtle.back)
  else
    moveSuccess = moveWithSave(moveFn)
  end
 

  -- Check if we want to move into safe zone. In this case dig will be turned off
  local safe = Turtle.safe or Turtle.safeZone(destination:unpack())
 
  -- Loop until we've successfully moved
  while not moveSuccess do
  
    -- We had too many attempts. Now we can only make error
    if attempt >= attemptsToFailure then
      safeCall(Turtle.onMoveFailure, newX, newY, newZ, direction)
    end
    
    -- Check if this move is forbidden. In this case change move to other way
    if attempt >= attemptsToAlternative then
      local alternative = Turtle.alterZone(Turtle.pos:unpack())
      local irrOrient = Turtle.getIrrespectiveOrient(direction)
      if alternative ~= nil and 
         alternative ~= irrOrient and 
         alternative ~= oppositeWay[irrOrient] then
        return Turtle.move(Turtle.getRelativeOrient(alternative), doNotTurnBack)
      end
    end
    
    -- Show that we are stuked a bit. Turn 360*
    if attempt>1 and attempt % attemptsToIndicate == 0 then
      for i=1,4 do Turtle.turnRight() end
    end
    
    -- Turn face to distraction to dig it if we are go backwards
    if isReceding then
      Turtle.turnRight(); Turtle.turnRight(); direction = way.FORWARD
      isReceding = false
    end
 
    -- If there is a block in front, dig it
    if detectFn() == true then
      if safe then
        -- If this is safe zone, we can dig anything except turtles
        local _, data = inspectFn()
        if data and data.name and not data.name:find("Turtle") then
          digFn()
        end
      else
        digFn()
      end
    else
      -- Am being stopped from moving by a mob, attack it
      attackFn()
    end

    -- Raise event if we try to move
    safeCall(Turtle.onMoveAttempt, attempt, newX, newY, newZ, direction)
      
    -- Try the move again
    moveSuccess = moveWithSave(moveFn)
    
    attempt = attempt + 1
    
    -- Random sleep between attempts
    if not moveSuccess then sleep(math.random()/10+0.1) end
  end
  
  Turtle.setPos(destination)
  
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
  if direct == way.UP or direct == way.DOWN then
    return direct
  else
    return (Turtle.orient + direct)%4
  end
end

function Turtle.getRelativeOrient(direct)
  if direct == way.UP or direct == way.DOWN then
    return direct
  else
    return math.abs(Turtle.orient - direct)%4
  end
end


 
--===========================================================
-- Find path to coordinates, avoid block listed cells
-- Using A* algorithm http://pastebin.com/CHCB8nDz
--===========================================================
function Turtle.pathTo(...)
  local args = {...}
  local x,y,z

  -- Overload to working with vectors
  if type(args[1]) == 'string' then
    if Turtle.beacons[args[1]] then
      x,y,z = Turtle.beacons[args[1]]:unpack()
    else
      return false
    end
  elseif type(args[1]) == 'table' then
    x,y,z = args[1]:unpack()
  else
    x,y,z = ...
  end
  assert(x and y and z, 'Wrong Turtle.pathTo() params')
  
  -- Already here!
  if Turtle.pos.x==x and Turtle.pos.y==y and Turtle.pos.z==z then return true end

  -- Get first crumb of path
  local crumb = AStarFindPath(Turtle.world, Turtle.pos, vec3(x,y,z))
  
  if crumb then
    -- Run over all crumbs 
    while crumb.next ~= nil do
      crumb = crumb.next
      Turtle.goTo(crumb.pos.x,crumb.pos.y,crumb.pos.z)
    end
  else
    -- Path cant be found. Move straight
    error("Path cant be found! From:".. tostring(vec3(Turtle.pos.x,Turtle.pos.y,Turtle.pos.z)) .." To:" ..tostring(vec3(x,y,z)))
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
  if type(args[1]) == 'string' then
    if Turtle.beacons[args[1]] then
      x,y,z = Turtle.beacons[args[1]]:unpack()
    else
      return false
    end
  elseif type(args[1]) == 'table' then
    x,y,z = args[1]:unpack()
  else
    x,y,z = ...
  end
  assert(x and y and z, 'Wrong Turtle.goTo() params')

  local targetPos = vec3(x,y,z)
  local targetVec = targetPos - Turtle.pos
  
  -- We need additional loop for cases of one way roads
  while not (targetPos == Turtle.pos) do
  
    -- X
    while Turtle.pos.x ~= x do
      if (targetVec.x<0 and Turtle.orient==way.RIGHT)   or
         (targetVec.x>0 and Turtle.orient==way.LEFT)    then
        Turtle.back(true)
      elseif (x<Turtle.pos.x) then
        Turtle.setOrient(way.LEFT)
        Turtle.forward()
      elseif (x>Turtle.pos.x) then
        Turtle.setOrient(way.RIGHT)
        Turtle.forward()
      end
    end
    
    
    
    -- Y
    while Turtle.pos.y ~= y do
      if(targetVec.y<0 and Turtle.orient==way.FORWARD) or
        (targetVec.y>0 and Turtle.orient==way.BACK)    then
        Turtle.back(true)
      elseif (y<Turtle.pos.y) then
        Turtle.setOrient(way.BACK)
        Turtle.forward()
      elseif (y>Turtle.pos.y) then
        Turtle.setOrient(way.FORWARD)
        Turtle.forward()
      end
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
function Turtle.setBeacon(beaconName, _x,_y,_z)
  Turtle.beacons[beaconName] = vec3(_x,_y,_z)
  Turtle.saveData()
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
-- Select empty slot
-- ********************************************************************************** --
function Turtle.selectEmptySlot()
  for i=1, 16 do
    if( turtle.getItemCount(i) == 0) then
      turtle.select(i)
      return true
    end
  end
  return false
end

-- ********************************************************************************** --
-- Select slot with data name as pattern
-- ********************************************************************************** --
function Turtle.select(str, isPattern)
  for i=1, 16 do
    if turtle.getItemCount(i) > 0 then
      local data = turtle.getItemDetail(i)
      if data and data.name then
        if isPattern then
          if data.name:find(str) then turtle.select(i); return i end
        else
          if data.name == str then turtle.select(i); return i end
        end
      end
    end
  end
  return nil
end


-- ********************************************************************************** --
-- Inspect item using direction
-- ********************************************************************************** --
function Turtle.inspect(direction)
  assert(direction==way.FORWARD or direction==way.UP or direction==way.DOWN, 'Wrong Turtle.inspect() params')
  return trtlOperationBySide[direction][8]()
end

-- ********************************************************************************** --
-- Place item. Check if item already placed.
-- ********************************************************************************** --
function Turtle.place(itemSlot, direction, noChecks)
  direction = direction or way.FORWARD
  assert(direction==way.FORWARD or direction==way.UP or direction==way.DOWN, 'Wrong Turtle.place() params')
  
  local _, detectFnc, _, attackFnc, compareFnc, _, placeFnc = unpack(trtlOperationBySide[direction])
  noChecks = noChecks or false
  
  -- slotsPattern is array of 16 nubbers that represent
  -- what kind of blocks lying in what kind of
  if itemSlot then
    turtle.select(itemSlot)
  end
  
  local placeSucces = false
  local digCount = 0
  local maxDigCount = 20
  local attempt = 0

  
  -- Check if there is already item  then try to place
  placeSucces = placeFnc()
  
  if noChecks then return placeSucces end
  
  if (not placeSucces) and detectFnc()  then
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
  while ((placeSucces == false) and (digCount < maxDigCount)) and attempt < attemptsToFailure do
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


--===========================================================
-- Touching is way to communicate with other turtles
-- using redstone signals 0-15
--===========================================================
local sidesList = {"top", "bottom", "left", "right", "front", "back"}
function Turtle.touch(strenght, direction, sleepTime)
  direction = direction or way.FORWARD -- Optional param
  sleepTime = sleepTime or 0.1
  
  
  if direction == -1 then
    local oldOut = {}
    for i=1, #sidesList do
      insert(oldOut, rs.getAnalogOutput(sidesList[i]))
      rs.setAnalogOutput(sidesList[i], strenght)
    end
    sleep(sleepTime)
    for i=1, #sidesList do
      rs.setAnalogOutput(sidesList[i], oldOut[i])
    end
  else
    local oldOutput = rs.getAnalogOutput(cc_sides[direction])
    rs.setAnalogOutput(cc_sides[direction], strenght)
    sleep(sleepTime)
    rs.setAnalogOutput(cc_sides[direction], oldOutput)
  end
end

--===========================================================
-- Feel the touches
--===========================================================
function Turtle.sense(direction, timeout)
  direction = direction or way.FORWARD -- Optional param
  
  -- Start the timer
  local timer, sFilter
  if nTimeout then
    timer = os.startTimer( timeout )
  else
    sFilter = "redstone"
  end
  
  while true do
    local sEvent, p1, p2, p3, p4, p5 = os.pullEvent( sFilter )
    
    if sEvent == "redstone" then
      if direction == -1 then
        for i=1, #sidesList do
          local strenght = rs.getAnalogInput(sidesList[i])
          if strenght > 0 then return strenght, sidesList[i] end
        end
      else
        local strenght = rs.getAnalogInput(cc_sides[direction])
        if strenght > 0 then return strenght end
      end
    elseif sEvent == "timer" then
      -- Return nil if we timeout
      if p1 == timer then
        return nil
      end
    end
  end
end