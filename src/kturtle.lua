-- ********************************************************************************** --
-- **   Main file of KrutoyTurtle program                                          ** --
-- **                                                                              ** --
-- **   User interface, fill algirithm code.                                       ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- Redefine global function for faster acces
local floor = math.floor


------------------------------------------------------
-- Filling function variables                       --
------------------------------------------------------

-- Main patterns, using in fill() function
--  Numbers tell what the count block will be placed
--  Exists: fillPattern[name][z][y][x]
--  [space]: here will no block
--  0: remove block here
fillPattern = {
  ['Plain'] =
  { {'1'} },
  ['BoxGrid'] =
   {{'3222';
     '2111';
     '2111';
     '2111';},
    {'2111';
     '1   ';
     '1   ';
     '1   ';},
    {'2111';
     '1   ';
     '1   ';
     '1   ';},
    {'2111';
     '1   ';
     '1   ';
     '1   ';}}
}


--[[ List of avaliable flags
  hollow,         -- Only box without bulk
  sides,          -- Making boxes without corners
  corners,        -- Making frames
  mirror,         -- Pattern texture will mirrored
  mirror -1,      -- Each mirrored pattern indexes will shif by one block
  mirror -1x,
  mirror -1y,
  mirror -1z,
  y->,            -- Build first x-z blocks, then go to next y layer
  x++, x--,       -- Shift next coord. Userful for stairs
  y++, y--,
  z++, z--,
  clear,          -- Replaces all pattern indexes to -1
  clearAllSkipped,-- Replaces all nil to 0
  skipClearing,   -- Replaces all 0 to nil
  tunnel, tube    -- tunnel without caps on start end end
]]


------------------------------------------------------
-- Other variables                                  --
------------------------------------------------------

-- Enumeration to store names for the 6 directions
local way = { FORWARD=0, RIGHT=1, BACK=2, LEFT=3, UP=4, DOWN=5 }
local wayName = { [0]='Forward', ' Right', 'Back', 'Left', 'Up', 'Down'}

local MAXTURTLES = 128 -- Maximum amount of turtles in swarm


------------------------------------------------------
-- Debug in IDE                                     --
------------------------------------------------------
IDE = (term==nil) and true or false

if IDE then
  loadfile('CC_emulator.lua')()
  loadfile('src/Thread.lua')()
  loadfile('src/Swarm.lua')()
  loadfile('src/KUI.lua')()
  loadfile('src/KTurtle.lua')()
  loadfile('src/TableToString.lua')()
  
  thread.create = function()end
  KUI.navigate  = function()end
  KUI.drawText  = function()end
  KUI.drawTextPanel= function()end
  KUI.setWindow= function()end
end

local function BREACKPOINT()
  print("DEBUG")
  while true do
    local dbgFnc = setfenv(loadstring(read()), getfenv(1))
    local status, err = pcall(dbgFnc)
    if err then print(); print(err) else return end
  end
end


-- ################################################################################## --
-- ##                                Utilities                                     ## --
-- ################################################################################## --


--===========================================================
-- Make keys from values
--===========================================================
local function makeSet(list)
  local set = {}
  for _, v in pairs(list) do set[v] = true end
  return set
end

--===========================================================
-- Just simplyfied sub function
--===========================================================
local function getChar(str, pos)
  return string.sub(str, pos, pos)
end

--===========================================================
-- Devide giving space to parts
--===========================================================
local function allocateCargo(cargoSlots, ...)
  local args = {...}
  assert(#args ~= 0, "Wrong allocateCargo parameters")

  local cargoCount = #args
  local arr = {}
  
  if cargoCount==1 then
    -- We havent weights, just count of slots
    local slices = args[1]
    local intPart = floor(cargoSlots/slices)
    local residue = cargoSlots % slices
    for i=1,slices do
      table.insert(arr, intPart + (residue>=1 and 1 or 0))
      residue = residue - 1
    end
  else
    -- We have weight array, devide by weight
    local fullWeight=0
    for i=1, #args do fullWeight = fullWeight+args[i] end
    local residue = cargoSlots
    -- Give each slot weight 1
    for i=1, #args do 
      table.insert(arr, 1)
      residue = residue - 1
    end
    local tmpResidue = residue
    for i=1, #args do 
      local prtVal = floor(args[i]/fullWeight*tmpResidue)
      arr[i] = arr[i] + prtVal
      residue = residue - prtVal
    end
    for i=1, #args do
      arr[i] = arr[i] + (residue>=1 and 1 or 0)
      residue = residue - 1      
    end
  end
  
  return arr
end

--===========================================================
-- Clear screen and set cursor to start
--===========================================================
local function clear()
   term.clear()
   term.setCursorPos (1,1)
end


--===========================================================
-- Waiting untill user press key
--===========================================================
local function pressAnyKey()
  local event, param1 = os.pullEvent ("key")
end

--===========================================================
-- Writes requestText and wait while user press number key
--===========================================================
local function readNumberParametr(requestText, from, to)
  while true do
     clear()
     print (requestText)
     local event, param1 = os.pullEvent ("char") -- limit os.pullEvent to the char event
     local result = tonumber(param1)
     if type(result) == 'number' and result >= from and result <= to then
         return result
     end
  end
end

--===========================================================
-- Read user input and separate into table
--===========================================================
local function readTable(separator)
  local resultStr = read()
  if resultStr ~= '' then
    local result = {}
    for v in string.gmatch(resultStr, separator) do
      table.insert(result,v)
    end
    return result
  end
  return nil
end

--===========================================================
-- Writes requestText and wait while user type several numbers
--===========================================================
local function readNumbersInput(cursorX, cursorY, canBeSkipped, numbersCount, separator)
  local result = {}
  for i=1,numbersCount do result[i]=0 end
  

  while true do
    term.setCursorPos(cursorX, cursorY)
    term.clearLine()
    local returnedResult = readTable(separator)
   
    if not returnedResult and canBeSkipped == true then
      return result
    elseif(returnedResult)then
      local isAllNumbers = true
      for i=1,numbersCount do
        if(type(tonumber(returnedResult[i])) == "number") then
          result[i] = tonumber(returnedResult[i])
        else
          term.write(returnedResult[i]..' is not number!')
          sleep(1)
          isAllNumbers=false
        end
      end
     
      if isAllNumbers == true then
        return result
      end
    end
  end
end

--===========================================================
-- Parse pattern from user-readable to table struct
--===========================================================
local function parsePattern(ptrn)
  -- Pattern sizes per axis
  local ptSzX, ptSzY, ptSzZ = 0,0,0
  
  -- Get sizes of pattern
  local zCount = #ptrn
  ptSzZ = zCount
  for z=1, zCount do
    local yCount = #ptrn[z]
    if ptSzY < yCount then ptSzY = yCount end
    for y=1, yCount do
      local xCount = #ptrn[z][y]
      if ptSzX < xCount then ptSzX = xCount end
    end
  end
  
  local parsedPattern = {}
  for z=1, ptSzZ do
    parsedPattern[z] = {}
    for y=1, ptSzY do
      parsedPattern[z][y] = {}
      for x=1, ptSzX do
        parsedPattern[z][y][x] = tonumber(getChar(ptrn[z][y], x))
      end
    end
  end
  
  return parsedPattern
end


--===========================================================
-- Just leave numbers in pattern, if in blacklist is 0
--===========================================================
local function selectPatternByBlacklist(pattern, blacklist)
  local resultPattern = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  for i=1, 16 do
      if(blacklist[i] == 0) then resultPattern[i] = pattern[i] end
  end
  return resultPattern
end

--===========================================================
-- Searching if wee have needed item in inventory
--===========================================================
local function findInSlotsArrayByPattern(arr, n, blacklist)
  blacklist = blacklist or {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  
  -- Set indexes to 0 if blacklist here is 1
  local filteredArr = selectPatternByBlacklist(arr, blacklist)

  for i=1, 16 do
    if(filteredArr[i] == n) and (turtle.getItemCount(i) > 0) then
      return i
    end
  end
  return 0
end


-- ################################################################################## --
-- ##                                PROGRAMS                                      ## --
-- ################################################################################## --




--===========================================================
-- Computing volume by given pattern
-- pos is shift fo pattern
--===========================================================
local function computeFillVolume(pos, size, gsize, patternId, fillFlags)

  -- ==============================
  -- Variables
  -- ==============================
  
  patternId = patternId or 'plain' -- Default pattern index - plain fill
  
  pos = pos  or vec3()
  size= size or vec3()
  
  local sizeX,sizeY,sizeZ    = size:unpack()
  local gsizeX,gsizeY,gsizeZ = gsize:unpack()
  
  local totalVolume = sizeX*sizeY*sizeZ -- Total volume of blocks
  local vol = {{{}}} -- 3d array of whole volume filling territory
 
  -- Statistics
  local stats = {}
  stats.totalBlocksToPlace    = 0  -- Total count of blocks that must be placed
  stats.totalBlockByIndex = {} -- Blocks count by indexes
  stats.totalFuelNeeded       = 0
  
  
  -- Auto flags
  if fillFlags['hollow'] then fillFlags['sides'] = true; fillFlags['corners'] = true end


  -- ==============================
  -- Preparing
  -- ==============================
  
  -- Write new pattern
  local parsedPattern = fillPattern[patternId]
    
  -- Pattern sizes per axis
  local ptSzX, ptSzY, ptSzZ = 0,0,0
  
  -- Get sizes of pattern
  for z,vy in pairs(parsedPattern[patternId]) do
    if ptSzZ < z then ptSzZ = z end
    
    for y,vx in pairs(vy) do
      if ptSzY < y then ptSzY = y end
      
      for x,v in pairs(vx) do
        if ptSzX < x then ptSzX = x end
      end
    end
  end
 
 
  
  -- We must make a large
  -- array of all blocks in volume
  for O=0, totalVolume-1 do
    local s_u, s_v, s_w
    s_u = floor(O/(sizeX*sizeY)) -- z
    s_v = floor(O/sizeX) % sizeY -- y
    s_w = floor(O%sizeX)         -- x
    
    local u,v,w = s_u+pos.z, s_v+pos.y, s_w+pos.x
   

    -- Pattern picker must think we are on this 'imagined' or 'fabled' positions
    local fabled_u, fabled_v, fabled_w = u, v, w
    if(fillFlags['mirror -1'] or fillFlags['mirror -1z']) then
      fabled_u = fabled_u + floor( (u+ptSzZ-1) / (ptSzZ*2-1) )
    end
    if(fillFlags['mirror -1'] or fillFlags['mirror -1y']) then
      fabled_v = fabled_v + floor( (v+ptSzY-1) / (ptSzY*2-1) )
    end
    if(fillFlags['mirror -1'] or fillFlags['mirror -1x']) then
      fabled_w = fabled_w + floor( (w+ptSzX-1) / (ptSzX*2-1) )
    end

    -- Compute pattern array indexes. Place on pattern that we want to take
    local ptX, ptY, ptZ = fabled_w%ptSzX, fabled_v%ptSzY, fabled_u%ptSzZ
    
    -- Flag "mirror" must mirrored all coordinates on even step
    if(fillFlags['mirror'] or fillFlags['mirror -1'] or fillFlags['mirror -1x'] or
       fillFlags['mirror -1y'] or fillFlags['mirror -1z']) then
      if (floor(fabled_w/ptSzX) % 2) == 1 then ptX = ptSzX-ptX-1 end
      if (floor(fabled_v/ptSzY) % 2) == 1 then ptY = ptSzY-ptY-1 end
      if (floor(fabled_u/ptSzZ) % 2) == 1 then ptZ = ptSzZ-ptZ-1 end
    end


    -- Get block index from pattern, demands on position of turtle
    local blockIndex = nil -- nil: avoid this block
    if parsedPattern[ptZ+1] and parsedPattern[ptZ+1][ptY+1] then
      blockIndex = parsedPattern[ptZ+1][ptY+1][ptX+1]
    end
    
   
    -- When we use 'sides' or 'corners' flags, we avoid all blocks inside volume
    if fillFlags['sides'] or fillFlags['corners'] then
      if(u>0 and u<gsizeZ-1) and (v>0 and v<gsizeY-1) and (w>0 and w<gsizeX-1) then
        blockIndex = 0
      end
    end
    
    -- If only 'sides' flag enabled, clear all corners
    if fillFlags['sides'] and not fillFlags['corners'] then
      if not(((u>0 and u<gsizeZ-1) and (v>0 and v<gsizeY-1)) or
             ((u>0 and u<gsizeZ-1) and (w>0 and w<gsizeX-1)) or
             ((w>0 and w<gsizeX-1) and (v>0 and v<gsizeY-1))) then
        blockIndex = 0
      end
    end
    
    -- If only 'corners', clear all sides
    if fillFlags['corners'] and not fillFlags['sides'] then
      if not(((u==0 or u==gsizeZ-1) and (v==0 or v==gsizeY-1)) or
             ((u==0 or u==gsizeZ-1) and (w==0 or w==gsizeX-1)) or
             ((w==0 or w==gsizeX-1) and (v==0 or v==gsizeY-1))) then
        blockIndex = 0
      end
    end
    if fillFlags['tunnel'] and (w>0 and w<gsizeX-1) and (u>0 and u<gsizeZ-1) then
      blockIndex = 0
    end
    if fillFlags['tube']   and (w>0 and w<gsizeX-1) and (v>0 and v<gsizeY-1) then
      blockIndex = 0
    end
    if fillFlags['clearAllSkipped'] then if blockIndex== nil then blockIndex = 0 end end
    if fillFlags['skipClearing']    then if blockIndex==   0 then blockIndex = nil end end
    
    -- Clear all blocks, ignoring any pattern
    if fillFlags['clear'] then blockIndex = 0 end
  
  
    -- Add tables if they are not defined
    if not vol[s_u]           then vol[s_u]           = {} end
    if not vol[s_u][s_v]      then vol[s_u][s_v]      = {} end
    
    -- Put block index in volume array
    vol[s_u][s_v][s_w] = blockIndex
    
    -- Statistics
    if blockIndex ~= nil and blockIndex ~= 0 then
    
      -- Create key for new type
      if not stats.totalBlockByIndex[blockIndex] then stats.totalBlockByIndex[blockIndex] = 0 end
    
      -- Increment counters
      if(blockIndex>0)then
        stats.totalBlocksToPlace = stats.totalBlocksToPlace + 1
        stats.totalBlockByIndex[blockIndex] = stats.totalBlockByIndex[blockIndex] + 1
      end
    end
  end
  
  -- More statistics
  stats.totalFuelNeeded = sizeX*sizeY*(2 + floor(sizeZ/3))
  
  -- Compute suggest pattern
  local suggestPattern = {}
  local blockList    = {}
  local blockIdxs    = {}
  local slotsToIndex = {}
  for i=1,16 do
    if stats.totalBlockByIndex[i] and stats.totalBlockByIndex[i] > 0 then
      table.insert(blockList, stats.totalBlockByIndex[i])
      table.insert(blockIdxs, i)
    end
  end
  if #blockList == 0 then
    slotsToIndex[0] = 16
    for j=1, 16 do table.insert(suggestPattern, 0) end
  elseif #blockList == 1 then
    slotsToIndex[1] = 16
    for j=1, 16 do table.insert(suggestPattern, blockIdxs[1]) end
  else
    local cargo = allocateCargo(16, unpack(blockList))
    for i=1,#cargo do
      slotsToIndex[blockIdxs[i]] = cargo[i]
      for j=1, cargo[i] do table.insert(suggestPattern,blockIdxs[i]) end
    end
  end
  stats.suggestPattern = suggestPattern
  stats.typesCont = #blockIdxs
  stats.slotsToIndex = slotsToIndex
  
  
  
  return vol, stats
end  


--===========================================================
-- Super-duper cool building program.
-- Using pre-made volume to fill it
--===========================================================
local function fill(vol, pos, size, fillFlags, stats)

  -- ==============================
  -- Preparing
  -- ==============================
  if not pos then pos = vec3(0,1,0) end -- Default position: forward from turtle
  local sizeX, sizeY, sizeZ = size:unpack()
  
  -- Preparing world for path finding
  -- Note that world is only in filling volume and starts for [0,0,0]
  local wrldSize = size+pos
  local localWorld = World.new(wrldSize:unpack())
  
  -- Block some cells to prevent gouing on forbidden places
  for z=2, wrldSize.z-1 do
    for x = 0, wrldSize.x-1 do
      localWorld.blocked[z][0][x] = true
    end
  end
    
  -- There we will storage what slots was deplited, out of building blocks
  -- 0: slot in use, have blocks.
  -- 1: slot deplited, haven't blocks or have thrash
  local blacklistPattern = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  
  local isGoBackAfterFill = true
  local slotsPattern
  local startPos = Turtle.pos:clone()
  local armedByIndex = {}
  
  -- Make array representing how much blocks each type we need to place
  -- Each time block placed value will be decremented
  stats.totalBlockByIndexLeft = {}
  for k,v in pairs(stats.totalBlockByIndex) do stats.totalBlockByIndexLeft[k] = v end
  

  
  -- ==============================
  -- Functions
  -- ==============================
  
  local fillGetPos = function(x,y,z)
    -- Shift next coord with flags
    -- Userful for stairs and diagonals
    local shift = vec3()
    if y then shift.x = y*(fillFlags['x++'] and 1 or (fillFlags['x--'] and -1 or 0)) end
    if x then shift.y = x*(fillFlags['y++'] and 1 or (fillFlags['y--'] and -1 or 0)) end
    if y then shift.z = y*(fillFlags['z++'] and 1 or (fillFlags['z--'] and -1 or 0)) end
    
    local changeVec = pos + shift    
    
    -- nil means we dont need change current position
    if not x then x = Turtle.pos.x-changeVec.x end
    if not y then y = Turtle.pos.y-changeVec.y end
    if not z then z = Turtle.pos.z-changeVec.z end

    local targetPos = vec3(x,y,z) + changeVec
    return targetPos
  end
  
  -- Function same as GoTo, but consider position of building and incremental shifting
  local _fillGoToFnc = function(x,y,z)
    Turtle.goTo(fillGetPos(x,y,z))
  end
  local _fillPathToFnc = function(x,y,z)
    Turtle.pathTo(fillGetPos(x,y,z))
  end
  
  -- Sometimes we need using safe way to go, so we will need to
  -- switch this handle to _fillPathToFnc
  local fillGoToFnc = _fillGoToFnc


  -- If we handle some unsolutionabled error, we can hope only on user.
  -- Going to start and waiting until he fix all
  local backToStartFnc = function(msg)
    print()
    print(msg)
    
    Turtle.pathTo(localWorld, 0,0,0)
    Turtle.setOrient(way.FORWARD)
    
    pressAnyKey()
  end
  
  -- Go to the storage and suck needed blocks. Storage must be defined
  local reloadForFilling = function(slotsPattern, blacklistPattern)
    
    local reloadedIndexes = {}
    
    -- Default blacklist. No thrash to drop
    if(blacklistPattern==nil) then blacklistPattern = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} end
    
    -- First, unload blacklisted slotls
    -- This is blocks that we dont using for building
    local strgPos = vec3()
    if Turtle.beacons["storageStart"] then strgPos = Turtle.beacons["storageStart"] end
    for i=1, 16 do
      if( blacklistPattern[i] > 0) then
        Turtle.goTo(strgPos)
        Turtle.setOrient(way.LEFT)
        
        turtle.select(i)
        turtle.drop()
      end
    end
    
    -- Then move to storages and take blocks
    for i=1, 16 do
      local texelIndex = slotsPattern[i]
      local hungryForCount = stats.totalBlockByIndex[texelIndex] - (armedByIndex[texelIndex] or 0)
      local itemSpace = turtle.getItemSpace(i)
      local already   = turtle.getItemCount(i)
      local needToSuck= math.min(itemSpace, hungryForCount)
      if( needToSuck > 0  and texelIndex > 0) then
        Turtle.goTo((texelIndex-1)*2 +strgPos.x, strgPos.y, strgPos.z)
        Turtle.setOrient(way.BACK)
        turtle.select(i)
        if turtle.suck(needToSuck) then
          -- Yes, we sucked something. Lets write it in pattern
          reloadedIndexes[texelIndex] = true
          local sucked = turtle.getItemCount(i) - already
          
          -- Show how much items we already have on board
          armedByIndex[texelIndex] = (armedByIndex[texelIndex] or 0) + sucked
        end
      end
    end
    
    return reloadedIndexes
  end

  -- Go to start and try reload while accomplished
  local reloadFnc = function()
  
    local isReloaded = false
    
    while not isReloaded do
      if Turtle.pos.y > 0 then Turtle.pathTo(localWorld, 0,0,0) end
      local reloadedIndexes = reloadForFilling(slotsPattern, blacklistPattern)
     
      -- Check if we reloaded all blocks
      local lastIndex = 0
      isReloaded = true
      for i=1, 16 do
        if slotsPattern[i] ~= lastIndex then
          lastIndex = slotsPattern[i]
          if not reloadedIndexes[lastIndex] then
            -- Seems like this index isn't reloaded
            isReloaded = false
          end
        end
      end
      
      if not isReloaded then
        backToStartFnc('Error: Reloading failed. Please make storage and press any key')
      end
    end
    blacklistPattern = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- Clear blacklist because we reloaded all
  end
  
  
  -- Get slot pattern.
  do  
    -- Search if turtle have anought tipes is inventory
    local typesExist = 0
    local ptrn = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- Standart pattern. All slots empty
    local lastUnemptySlot = 0
    local lastEnum = 1
    
    for i=1, 16 do
      turtle.select(i)
      if( turtle.getItemCount(i) > 0) then
        if (lastUnemptySlot == 0) then
          lastUnemptySlot = i
        elseif (i>1) and (turtle.compareTo(lastUnemptySlot) == false) then
          lastEnum = lastEnum + 1
          lastUnemptySlot = i
        end
        
        typesExist = typesExist + 1
        ptrn[i] = lastEnum
      end
    end    
    
    if stats.typesCont > typesExist then
      -- We have not anought items in inventory and need to use suggested pattern
      -- So we need to reload
      slotsPattern = stats.suggestPattern
      reloadFnc()
    else
      -- Just work with items we have inside
      slotsPattern = ptrn
    end
  end


  

  -- The main function of placing blocks with parameters
  local fillFnc = function(x,y,z,direct,orient, blockIndex)
    -- nil means skipping
    if blockIndex == nil then return nil end
  
    -- Error text only for fatals, where program cant do nothing
    local fillError
    
    repeat -- Repeat until no fillErrors
      fillError = nil

      if blockIndex > 0 then
        local slotWithBlock = findInSlotsArrayByPattern(slotsPattern, blockIndex, blacklistPattern)
        if(slotWithBlock ~= 0) then
          fillGoToFnc(x,y,z)
          fillGoToFnc = _fillGoToFnc -- Restore in case it was "pathTo" way
          if orient then Turtle.setOrient(orient) end -- Can be nil - orientation don't matter
          
          -- We have block and can put it on place
          local placeSucces = Turtle.place(slotWithBlock, direct)
          
          if(placeSucces == true)then
            -- Block this cell in world, make it unable to go throught
            local blockPos = Turtle.getRelativeCoord(direct)
            localWorld.blocked[blockPos.z][blockPos.y][blockPos.x] = true
            
            -- Decrement block for placing
            stats.totalBlockByIndexLeft[blockIndex] = stats.totalBlockByIndexLeft[blockIndex] - 1
          end
         
          -- If slot was emptyed, we must note, that now there will be thrash
          -- Each next time when turtle dig, empty slot will filling
          if(turtle.getItemCount(slotWithBlock) == 0) then
            blacklistPattern[slotWithBlock] = 1
            
            -- Check again if we have another slot with item
            if findInSlotsArrayByPattern(slotsPattern, blockIndex, blacklistPattern) == 0 and
              stats.totalBlockByIndexLeft[blockIndex] > 0  then
              -- No avaliable blocks to build!
              -- Save coords, reload and return
              local stopPos = Turtle.pos:clone()
              
              reloadFnc()
              
              -- Go back to work
              Turtle.pathTo(localWorld, stopPos)
            end
          end
        else
          -- Fatal fillError. We are probably reloaded, but still havent blocks to place
          -- This can happend only with bug in code
          fillError = 'Fatal Fill Error: No blocks to place on {'..x..','..y..','..z..'}. I dont know what went wrong. '
          backToStartFnc(fillError)
        end
      else -- blockIndex == 0
        fillGoToFnc(x,y,z)
        fillGoToFnc = _fillGoToFnc -- Restore in case it was "pathTo" way
        if(orient)then Turtle.setOrient(orient) end -- Can be nil - orientation don't matter
        
        -- Remove block here and do nothing
        Turtle.dig(direct)
      end
    until not fillError
    
    return nil
  end -- fillFnc()

  
  --[[
  -- Show moving status on screen
  Turtle.onMoveAttempt = function(attempt, newX, newY, newZ, attDir)
    local scrW, scrH = term.getSize()
    term.setCursorPos (1,scrH-2)
    print(string.format('fill()   size:%i,%i,%i pos:%i,%i,%i',sizeX, sizeY, sizeZ, pos.x, pos.y, pos.z))
    print(string.format('[Turtle] pos:%i,%i,%i orient:%i',Turtle.pos.x, Turtle.pos.y, Turtle.pos.z,Turtle.orient))
    write(string.format('[WantTo] pos:%i,%i,%i dir:%i att:%i',newX, newY, newZ, attDir, attempt))
  end
  ]]--

  -- ==============================
  -- Iterators
  -- ==============================
  
  
  -- move to start position
  fillGoToFnc(0, 0, ((sizeZ>1) and 1 or 0))
  
  -- y-> is printing method, when we fill from us to forward
  if     fillFlags['y->'] then
    for _y=0, sizeY-1 do
      for _z=0, sizeZ-1 do
        for _x=0, sizeX-1 do
          local x,y,z = _x,_y,_z
          if(z%2==1) then x = sizeX-x-1 end -- Ping-pong
          
          fillFnc(x,y,z+1, way.DOWN, nil, vol[z][y][x])
        end
      end
    end
    
  -- Printer working as usual building programs
  elseif fillFlags['printer'] then
    for _z=0, sizeZ-1 do
      for _y=0, sizeY-1 do
        for _x=0, sizeX-1 do
          local x,y,z = _x,_y,_z
          if(z%2==1) then y = sizeY-y-1; x = sizeX-x-1 end -- Ping-pong
          if(y%2==1) then x = sizeX-x-1 end                -- Ping-pong
          
          fillFnc(x,y,z+1, way.DOWN, nil, vol[z][y][x])
        end
      end
    end
    
  -- And most awesome and fast filling method
  -- It filling 3 blocks per move
  else
    local zStepsCount    = math.ceil(sizeZ/3)-1 -- Count of levels, where robot moves horisontally
    local lastZStepIsCap = (sizeZ%3 == 1) -- The top level of volume is last level where turtle moves hor-ly
    local zLastStepLevel = zStepsCount*3+(lastZStepIsCap and 0 or 1) -- Z level where turtle will move last
    
    for _z=0, zStepsCount do
      for _y=0, sizeY-1 do
        for _x=0, sizeX-1 do
          local x,y = _x,_y
          x = sizeX - x - 1 -- Revert X coordinates. Filling will be from right to left
          
          local z = _z*3+1
          local currZStepIsLast = (_z==zStepsCount)
          if currZStepIsLast then z = zLastStepLevel end -- Cap of volume
          
          -- Ping-pong
          local currZIsEven = (_z%2==0)
          local horisontDirect = way.BACK -- Specific orientation, when we move to next Y pos
          local horisontShift  = -1       -- Y direction, when we move to next Y pos
          if not currZIsEven then
            y = sizeY - y - 1
            horisontDirect = way.FORWARD
            horisontShift = 1
          end          
          
          local escapeShaftHere = (x==0 and y==0)
          local hereWeWillGoUp = ((x==0 and ((_z%2==0 and y==sizeY-1) or (_z%2==1 and y==0))) and _z < zStepsCount)
          

          -- Fill down
          if z>0 and not (lastZStepIsCap and currZStepIsLast) and not escapeShaftHere then
            fillFnc(x,y,z, way.DOWN, nil, vol[z-1][y][x])
          end
          
          -- Fill forward
          if x < sizeX-1 then
            fillFnc(x,y,z, way.FORWARD, way.RIGHT, vol[z][y][x+1])
          end
          
          -- Fill back previous line when we starting new x line
          if not currZStepIsLast or (not currZIsEven and currZStepIsLast) then
            if x==0 and ((currZIsEven and y>0) or ((not currZIsEven) and y<sizeY-1)) and
             not (x==0 and y==1 and currZIsEven) then
              fillFnc(x,y,z, way.FORWARD, horisontDirect, vol[z][y+horisontShift][x])
            end
          end
          
          -- Fill UP
          if z<sizeZ-1 and not hereWeWillGoUp and (not escapeShaftHere or currZStepIsLast) then
            fillFnc(x,y,z, way.UP, nil, vol[z+1][y][x])
          end
          
          -- Go forward if we finished the line
          if x==0 and ((_z%2==0 and y<sizeY-1) or (_z%2==1 and y>0)) then
            Turtle.goTo(Turtle.pos.x, Turtle.pos.y-horisontShift, Turtle.pos.z)
          end
          
          -- Move up and fill bocks down, if we advance to next Z level
          if hereWeWillGoUp then
            local nextZLevel = (_z+1)*3 + 1
            if lastZStepIsCap and (_z+1==zStepsCount) then nextZLevel = nextZLevel-1 end -- Cap of volume
            if(escapeShaftHere)then
              fillGoToFnc = _fillPathToFnc -- Set function to save version
            else
              for zAdvance=z+1, nextZLevel do
                fillGoToFnc = _fillPathToFnc
                fillFnc(x,y,zAdvance, way.DOWN, nil, vol[zAdvance-1][y][x])
              end
            end
          end
          
        end
      end
    end
    
    -- We use our shaft to go back to x=0, y=0
    if not (zStepsCount%2==1) then
      for y=sizeY-2, 0, -1 do
        fillFnc(0, y, zLastStepLevel, way.FORWARD, way.FORWARD, vol[zLastStepLevel][y+1][0])
      end
    end
    
    -- And then go down to z 0
    for z=zLastStepLevel-1, 0, -1 do
      fillFnc(0, 0, z, way.UP, nil, vol[z+1][0][0])
    end
    fillGoToFnc(0,0,0)
    
    -- And last block
    fillFnc(0, -1, 0, way.FORWARD, way.FORWARD, vol[0][0][0])
  end
  
  
  -- ==============================
  -- Finishing
  -- ==============================
  
  -- Now we finished filling territory. Just go home
  if isGoBackAfterFill == true then
    Turtle.goTo(startPos)
    Turtle.setOrient(way.FORWARD)
  end
  
  return true
end

-- ################################################################################## --
-- ##                            Startup functions                                 ## --
-- ################################################################################## --
local args = { ... }

function main()

  -- Reparse tables from user-friendly to hardcore
  for k,v in pairs(fillPattern) do
    fillPattern[k] = parsePattern(v)
  end

  -- Get screen params
  local scrW, scrH = term.getSize()
  
  
  -- ==============================
  -- Slave
  -- ==============================
  local addZones = function(leftShift)
    local harborHeight = 10
    local maxWidth = 256
    Turtle.addBeacon("storageStart", leftShift, 0, 0)
    Turtle.addForbiddenWayZone(way.LEFT,  way.UP,   leftShift+1,0,0, leftShift+maxWidth,0,0)
    Turtle.addForbiddenWayZone(way.RIGHT, way.DOWN, leftShift  ,0,1, leftShift+maxWidth,0,1)
    
    Turtle.addAlterZone(way.UP,    leftShift+1,0,1, leftShift+maxWidth,0,harborHeight)
    Turtle.addAlterZone(way.RIGHT, leftShift  ,0,0, leftShift+maxWidth,0,0)
    
    Turtle.addSafeZone(leftShift,0,0, leftShift+maxWidth,0,harborHeight)
  end 

  local distToOwner
  local searchOwner = function()
    while true do
      distToOwner = swarm.searchOwner()
      
      -- Owner is found. Show this on screen
      KUI.setWindow({{ id='slaveLabel', type='textPanel', text='This turtle\nis slave.\n\nWaiting orders.',
              x=8,y=scrH/2-3, w=scrW-16,h=6}})
      
      -- This turtle is slave. Waiting orders and run them
      local fillParams
    
      while true do
        local orderFromOwner = swarm.waitOrders()
        
        if orderFromOwner.orderType == 'fillOptions' then
          fillParams = orderFromOwner
          
          if turtle.getFuelLevel() <= fillParams.stats.totalFuelNeeded then
            -- Turtle have problems. It must send this to owner.
            swarm.transmitError('Rquire fuel level: ' .. fillParams.stats.totalFuelNeeded)
          end
          
        elseif orderFromOwner.orderType == 'lash' then
          -- IMPORTANT:
          -- We changing self-position to turtle. It will think that we standing in negative coords
          Turtle.pos.x = -fillParams.pos.x + distToOwner
          addZones(-fillParams.pos.x)
          
          -- Fill
          fill(fillParams.volume, vec3(0,1,0), vec3(fillParams.size.x, fillParams.size.y, fillParams.size.z), fillParams.fillFlags, fillParams.stats)
        end
      end
    end
  end
  
  -- Do not show anything. Just wait if we had owner
  thread.create(searchOwner)
         
  -- ==============================
  -- Main menu
  -- Fill options
  -- ==============================
  local nextBtn = { id='btn_next', type='button',   text='Next>>',
      x=scrW-10,y=scrH,w=8,h=1, borderStyle='none'}
  
  local fillOptionsWindow = {} 
  table.insert(fillOptionsWindow,{ id='optionsLabel', type='textPanel', text='Fill options',
      x=0,y=0, w=scrW+2,h=3})
  local inputSize = { id='btn_size', type='input',    text='',
      x=3,y=6, w=scrW-13,h=1, borderStyle='none', align='left', padding={0,0,0,9}}
      
  table.insert(fillOptionsWindow,{ id='btn_pattern', type='button', text='Pattern: ""',
      x=3,y=4, w=scrW-4,h=1, borderStyle='none', align='left'})
  table.insert(fillOptionsWindow,{ id='txt_size', type='text',    text='   Size: ',
      x=3,y=6, w=9,h=1, borderStyle='none', align='left'})
  table.insert(fillOptionsWindow, inputSize)
  table.insert(fillOptionsWindow,{ id='btn_flags', type='button',   text='  Flags: _',
      x=3,y=8, w=scrW-4,h=1, borderStyle='none', align='left'})
  table.insert(fillOptionsWindow,nextBtn)
  
  
  
  while true do
  
    --[[
    -- Refuel from lava lake
    do
      -- Check is we have bucket
      while turtle.getItemCount(1) == 0 do
          KUI.setWindow({{ id='noBuketLabel', type='textPanel', text='Place buket in\nfirst slot',
              x=8,y=scrH/2-3, w=scrW-16,h=6}})
          sleep(1)
      end
      
      -- Offer user to input size
      KUI.setWindow({{ id='lakeLabel', type='textPanel',
        text='Specify size by x y z (z is deph)\n, separate with spaces, and press ENTER:',
        x=0,y=0, w=scrW+2,h=4}})
      local result = readNumbersInput(3, 6, false, 3, "%S+")
      local sizeX,sizeY,sizeZ = result[1],result[2] ,result[3]
      
      
      turtle.select(1)
      turtle.refuel()
      local startPos = vec3(Turtle.pos.x,Turtle.pos.y,Turtle.pos.z)
      for z=0,sizeZ-1 do
        for x=0,sizeX-1 do
          for y=0,sizeY-1 do
            if(x%2==1) then y = sizeY - y - 1 end -- Ping-pong
            Turtle.goTo(x,y+1,-z)
            turtle.placeDown()
            turtle.refuel()
            
            clear()
            print('Fuel level: '..turtle.getFuelLevel())
          end
        end
      end
      Turtle.goTo(Turtle.pos.x,Turtle.pos.y, startPos.z)
      Turtle.goTo(startPos)
      Turtle.setOrient(way.FORWARD)
    end
    ]]--


    local sizeX,sizeY,sizeZ 
    local pattern = nil
    local pos = vec3()
    local fillFlags = {}
    local optionId, sender = 'btn_pattern', nil
    
    
    if IDE then
      sizeX,sizeY,sizeZ, pattern, pos, fillFlags = 2, 3, 3,'BoxGrid', pos, {}
      optionId = 'btn_next'
    end
    
    -- Size input
    KUI.onKeyPressed = function(keyCode)
      if KUI.selectedObj.id == 'btn_size' then
        local inputText = KUI.selectedObj.text
        if inputText ~= "" then
          local result = {}
          for s in string.gmatch(inputText, "%S+") do
            if s == "-" then s = "-0" end
            table.insert(result,tonumber(s))
          end
          if #result == 3 then
            sizeX,sizeY,sizeZ = result[1],result[2],result[3]
          end
        end
      end
    end
    
    
    local helpTab = "btn_pattern"
    while optionId ~= 'btn_next' or not pattern or not sizeX or not sizeY or not sizeZ do
      KUI.setWindow(fillOptionsWindow, helpTab)
      optionId, sender = KUI.navigate()
      
      if     optionId == 'btn_pattern' then
        -- Fish all vox files in root
        local tmpPatternList = {}
        for k,_ in pairs(fillPattern) do table.insert(tmpPatternList, k) end
        for _,v in pairs(fs.list('')) do
          local fileExtension = string.sub(v,#v-3,#v)
          if fileExtension == '.vox' or fileExtension == '.nfa' and not fillPattern[v] then
            table.insert(tmpPatternList, v)
          end
        end
        
        -- Assemble string to show user and wait his choose
        local currLine = ''
        for k,v in pairs(tmpPatternList) do
          currLine = currLine..' '..k..' - '..v..'\n'
        end
        local result = readNumberParametr(currLine, 1, #tmpPatternList)
        
        -- Load needed files if we dont had them already
        local pattLen = tblLen(fillPattern)
        pattern = tmpPatternList[result]
        if result > pattLen then -- This pattern is file. Load File
          local fileExtension = string.sub(pattern,#pattern-3,#pattern)
          if fileExtension == '.nfa' then
            fillPattern[pattern] = volumeLoader.load_nfa(pattern)
          end
          if fileExtension == '.vox' then 
            fillPattern[pattern],sizeX,sizeY,sizeZ  = volumeLoader.load_vox(pattern)
            inputSize.text = sizeX..' '..sizeY..' '..sizeZ
          end
        end
        
        -- Show pattern key to user
        sender.text = 'Pattern: '..pattern
      elseif optionId == 'btn_size' then
      
      elseif optionId == 'btn_flags' then
        KUI.setWindow({{ id='flags_label', type='textPanel',
          text='Add flags if need, separate\with commas, and press ENTER',
          x=1,y=0, w=scrW,h=4}})
        term.setCursorPos(5,7)
        local result = readTable("%S+")
        if result then
          fillFlags = makeSet(result)
          sender.text = '  Flags: '.. table.concat(result,", ")
        end
      end
      if not pattern or not sizeX or not sizeY or not sizeZ then
        inputSize.text = (sizeX or '0')..' '..(sizeY or '0')..' '..(sizeZ or '0')
      end
      KUI.nextTab()
      helpTab = KUI.selectedObj.id
    end
    KUI.onKeyPressed = nil
    
    
    -- Volume of "owner" or "master" turtle
    local masterVolume, masterStats
    local gsize = vec3(sizeX,sizeY,sizeZ)
    local wholeVlume, wholeStats = computeFillVolume(pos, gsize, gsize, pattern, fillFlags)
          
    -- ==============================
    -- Find other turtles
    -- ==============================
    local errorsArray = nil
    local slavesCount = 0
    
    -- Loop while no errors sended from turtles
    repeat
    
      -- Show box that we waiting for slaves
      KUI.setWindow({{ id='findSlaves', type='textPanel', text='Trying to find slaves\nWait a sec...', x=8,y=scrH/2-3, w=scrW-16,h=6}})
      
      -- Broadcast message and get all responses
      slavesCount = swarm.findSlaves(MAXTURTLES/50)   ;if IDE then slavesCount = 1 end
      
      
      if(slavesCount > 0) then
        KUI.setWindow({{ id='slavesFound', type='textPanel', text='Slaves found!\nSending orders...', x=8,y=scrH/2-3, w=scrW-16,h=6}})
        
        local slices = allocateCargo(sizeX, slavesCount+1)
        local partCursor = 0
        
        for i=0, slavesCount do
          local size    = vec3(slices[i+1], sizeY, sizeZ)
          local prt_pos = vec3(partCursor, 0, 0)
          partCursor = partCursor + slices[i+1]
          
          -- Get volume for this part
          local volumePart, statPart = computeFillVolume(prt_pos, size, gsize, pattern, fillFlags)
          
          if i==0 then
            -- This turtle is master and we have slaves
            masterVolume, masterStats = volumePart, statPart
            addZones(0)
          else
            -- Prepare table with parameters for send
            local taskObj = {orderType='fillOptions', volume=volumePart, size={x=size.x,y=size.y,z=size.z},
                           pos={x=prt_pos.x,y=prt_pos.y,z=prt_pos.z}, fillFlags=fillFlags, stats=statPart}
            
            swarm.transmitTask(i, taskObj)
          end
        end
        
        -- Show that we sended volumes and wait errors
        KUI.setWindow({{ id='waitingWhine', type='textPanel', text='Orders sended.\nWait problems if had...', x=8,y=scrH/2-3, w=scrW-16,h=6}})
        errorsArray = swarm.receiveError(MAXTURTLES/50)
                  
        -- Show errors
        if errorsArray then
          local whineArrayStr = ""
          for k,v in pairs(errorsArray) do
            whineArrayStr = whineArrayStr .. 'Turt #' .. k .. ': ' .. v
          end
          KUI.setWindow({{ id='showWhine', type='textPanel', text='Huston!\n We have a problems:\n' .. whineArrayStr .. '\nPress ENTER', x=8, y=scrH/2-5, w=scrW-16,h=10}})
          read()
        end
      else -- slavesCount == 0
        masterVolume, masterStats = wholeVlume, wholeStats
      end
    until not errorsArray
    
    -- ==============================
    -- Info screen
    -- ==============================

    local infoText = ' INFO \n' .. 
                     'Fuel level:            ' .. (masterStats.totalFuelNeeded <= turtle.getFuelLevel() and 'OK' or 'NOT ENOUGHT!!') .. '\n' ..
                     'Blocks by type:\n'

    -- Print how much we need of blocks by each type
    for k,v in pairs(wholeStats.totalBlockByIndex) do
      local stacks   = floor(v/64)
      local modStacks= v%64
      infoText = infoText .. ' #'..k..': '..((stacks>0) and stacks..'x64' or '')..
        ((stacks>0 and modStacks>0) and ' + ' or '')..
        ((modStacks>0) and modStacks or '') .. '\n'
    end
    infoText = infoText ..'Press ANY KEY\n'
                     

    KUI.setWindow({{ id='fillInfo', type='textPanel', text=infoText, x=1, y=1, w=scrW,h=scrH, align='left'}})
    pressAnyKey()
    clear()
    
    -- Lash slaves
    for i=1, slavesCount do
      swarm.transmitTask(i, {orderType='lash'})
    end
    
    fill(masterVolume, pos+vec3(0,1,0), vec3(sizeX,sizeY,sizeZ), fillFlags, masterStats)
  end
end

-- Function, called in start of all.
if IDE then main() end
