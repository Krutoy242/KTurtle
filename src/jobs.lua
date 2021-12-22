

-- ################################################################################## --
-- ##                                PROGRAMS                                      ## --
-- ################################################################################## --



-- Looks like a class
jobs = {}
jobs.__index = jobs

--===========================================================
-- Computing volume by given pattern
-- pos is shift fo pattern
--===========================================================
function jobs.computeFillVolume(pos, size, gsize, pattern, fillFlags)

  -- ==============================
  -- Variables
  -- ==============================
  
  pos = pos  or vec3()
  size= size or vec3()
  
  local sizeX,sizeY,sizeZ    = size:unpack()
  local gsizeX,gsizeY,gsizeZ = gsize:unpack()
  
  local totalVolume = sizeX*sizeY*sizeZ -- Total volume of blocks
  local vol = arr3d() -- 3d array of whole volume filling territory
 
  -- Statistics
  local stats = {}
  stats.totalBlocksToPlace    = 0  -- Total count of blocks that must be placed
  stats.totalBlockByIndex = {} -- Blocks count by indexes
  stats.totalFuelNeeded       = 0
  stats.shelfX            = {} -- count of blocks on each X slice
  stats.shelfY            = {} -- count of blocks on each Y slice
  stats.shelfZ            = {} -- count of blocks on each Z slice
  stats.shelfZ_clear      = {} -- Determine if this Z level have something but 0
  
  
  -- Auto flags
  if fillFlags['hollow'] then fillFlags['sides'] = true; fillFlags['corners'] = true end
  if fillFlags['mine']   then fillFlags['clear'] = true; fillFlags['greedy']  = true end
  if fillFlags['ore']    then fillFlags['clear'] = true; fillFlags['greedy']  = true; fillFlags['mine']  = true end
  if fillFlags['lava']   then fillFlags['clear'] = true end



  -- ==============================
  -- Preparing
  -- ==============================
  
  -- Pattern sizes per axis
  local ptSzX, ptSzY, ptSzZ = 0,0,0
  
  -- Get sizes of pattern
  local rawPtrn = (pattern.raw and pattern:raw() or pattern)
  for z,vy in pairs(rawPtrn) do
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
    if pattern[ptZ+1] and pattern[ptZ+1][ptY+1] then
      blockIndex = pattern[ptZ+1][ptY+1][ptX+1]
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
    if fillFlags['wash'] then if blockIndex== nil then blockIndex = 0 end end
    if fillFlags['skip']    then if blockIndex==   0 then blockIndex = nil end end
    
    -- Clear all blocks, ignoring any pattern
    if fillFlags['clear'] then blockIndex = 0 end
    
    -- Put block index in volume array
    vol:set(s_w,s_v,s_u,blockIndex)
    
    -- Statistics
    if blockIndex then
      stats.totalBlocksToPlace = stats.totalBlocksToPlace + 1
      stats.totalBlockByIndex[blockIndex] = (stats.totalBlockByIndex[blockIndex] or 0) + 1
      
      -- Shelfes
      stats.shelfX[s_w] = (stats.shelfX[s_w] or 0) + 1
      stats.shelfY[s_v] = (stats.shelfY[s_v] or 0) + 1
      stats.shelfZ[s_u] = (stats.shelfZ[s_u] or 0) + 1
      
      -- True if this level have other then 0
      if stats.shelfZ_clear[s_u] == nil then stats.shelfZ_clear[s_u] = true end
      stats.shelfZ_clear[s_u] = stats.shelfZ_clear[s_u] and (blockIndex == 0)
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
      insert(blockList, stats.totalBlockByIndex[i])
      insert(blockIdxs, i)
    end
  end
  if #blockList == 0 then
    slotsToIndex[0] = 16
    for j=1, 16 do insert(suggestPattern, 0) end
  elseif #blockList == 1 then
    slotsToIndex[1] = 16
    for j=1, 16 do insert(suggestPattern, blockIdxs[1]) end
  else
    local cargo = splitJob(16, unpack(blockList))
    for i=1,#cargo do
      slotsToIndex[blockIdxs[i]] = cargo[i]
      for j=1, cargo[i] do insert(suggestPattern,blockIdxs[i]) end
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
function jobs.fill(...)
  local vol, pos, size, fillFlags, stats = ...

  -- ==============================
  -- Preparing
  -- ==============================
  local sizeX, sizeY, sizeZ = size:unpack()
  
  -- Preparing world for path finding
  -- Note that world is only in filling volume and starts for [0,0,0]
  local p1,p2 = pos, size+pos
  
  -- Block some cells to prevent gouing on forbidden places
  -- Bottom and Top
  Turtle.world:setVolume(p1.x, p1.y, p1.z-1, p2.x, p2.y, p1.z-1, true)
  Turtle.world:setVolume(p1.x, p1.y, p2.z+1, p2.x, p2.y, p2.z+1, true)
  -- Left and right
  Turtle.world:setVolume(p1.x-1, p1.y, p1.z, p1.x-1, p2.y, p2.z, true)
  Turtle.world:setVolume(p2.x+1, p1.y, p1.z, p2.x+1, p2.y, p2.z, true)
  -- Forth
  Turtle.world:setVolume(p1.x, p2.y+1, p1.z, p2.x, p2.y+1, p2.z, true)
  -- Inter point
  Turtle.world:set(0,1,0, nil)
  
    
  -- There we will storage what slots was deplited, out of building blocks
  -- 0: slot in use, have blocks.
  -- 1: slot deplited, haven't blocks or have thrash
  local blacklistPattern = {}
  
  local isGoBackAfterFill = true
  local slotsPattern
  local armedByIndex = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  Turtle.setBeacon("startPos", Turtle.pos:clone())
  
  -- Make array representing how much blocks each type we need to place
  -- Each time block placed value will be decremented
  local totalBlockByIndexLeft = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  for k,v in ipairs(stats.totalBlockByIndex) do totalBlockByIndexLeft[k] = v end
  
  -- We need to create array with cells where we already was, and then not need to dig
  -- in case we clearing then volume
  local clearedPionts = arr3d()
  if stats.totalBlockByIndex[0] then
    Turtle.onMove = function (attempt, newX, newY, newZ, direction)
      clearedPionts:set(Turtle.pos.x,Turtle.pos.y,Turtle.pos.z,true)
    end
  end
  
  --[[ Saving fill parameters
  do
    local f = fs.open(fillParamFile, "w")
    f.write(table.toString({...}))
    f.close()
  end]]--
  
 
  -- ==============================
  -- Functions
  -- ==============================
  
  local goThruGangway = function(...)
    if Turtle.pos.y ~= 0 or Turtle.pos.z~= 0 then
      Turtle.pathTo(0,1,0)
      Turtle.goTo(0,0,0)
    end
    Turtle.goTo(...)
  end
  
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
    
    goThruGangway("startPos")
    Turtle.setOrient(way.FORWARD)
    
    idle = true
    pressAnyKey()
    idle = false
  end

  local dropIfTidy = function()
    local itemsDropped = 0
    if fillFlags['tidy'] then
      for i=1,16 do
        turtle.select(i)
        local data = turtle.getItemDetail()
        if data and Turtle.isThrash(data.name) then
          itemsDropped = itemsDropped + turtle.getItemCount(i)
          turtle.dropDown()
        end
      end
    end
    return itemsDropped
  end
  
  -- Go to start and wait user help for fuel
  local alreadyWaitFuel = false
  Turtle.onLowFuel = function(newX, newY, newZ, direction)
    if alreadyWaitFuel == false then
      alreadyWaitFuel = true
      local oldFuelLevel = turtle.getFuelLevel()
      while turtle.getFuelLevel() <= oldFuelLevel do
        backToStartFnc('Low fuel! Place something to refuel and press ANY KEY')
        shell.run("refuel all")
      end
      alreadyWaitFuel = false
    end
  end
  
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
  
  
  -- Go to the storage and suck needed blocks. Storage must be defined
  local reloadForFilling = function()    
    -- First, unload blacklisted slotls
    -- This is blocks that we dont using for building
    local strgPos = Turtle.beacons["storageStart"]
     
    for i=1, 16 do
      if blacklistPattern[i] and turtle.getItemCount(i) > 0 then
        goThruGangway(strgPos)
        Turtle.setOrient(way.LEFT)
        
        turtle.select(i)
        turtle.drop()
        blacklistPattern[i] = nil
      end
    end
    
    -- Then move to storages and take blocks
    for i=1, 16 do
      local texelIndex = slotsPattern[i]
      local hungryForCount = (stats.totalBlockByIndex[texelIndex] or 0) - (armedByIndex[texelIndex] or 0)
      local itemSpace = turtle.getItemSpace(i)
      local already   = turtle.getItemCount(i)
      local needToSuck= math.min(itemSpace, hungryForCount)
      if( needToSuck > 0  and texelIndex > 0) then
        local chestStep = (fillFlags['dense'] and 1 or 2)
        goThruGangway((texelIndex-1)*chestStep +strgPos.x, strgPos.y, strgPos.z)
        Turtle.setOrient(way.BACK)
        turtle.select(i)
        if turtle.suck(needToSuck) then
          local sucked = turtle.getItemCount(i) - already
          
          -- Show how much items we already have on board
          armedByIndex[texelIndex] = armedByIndex[texelIndex] + sucked
        end
      end
    end
  end

  -- Go to start and try reload while accomplished
  local reloadFnc = function()
    -- Collect how much items we armed in reload session
    armedByIndex = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  
    local isReloaded = false
    
    while not isReloaded do
      reloadForFilling()
     
      -- Check if we reloaded all blocks
      local lastIndex = 0
      isReloaded = true
      for i=1, 16 do
        if slotsPattern[i] ~= lastIndex then
          lastIndex = slotsPattern[i]
          if totalBlockByIndexLeft[lastIndex] > 0 and armedByIndex[lastIndex] == 0 then
            -- Seems like this index isn't reloaded
            isReloaded = false
          end
        end
      end
      
      if not isReloaded then
        backToStartFnc('Error: Reloading failed. Please make storage and press any key')
      end
    end
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
      -- we should use pattern that we get ourself.
      -- But if we clearing, pattern mus be clear
      if fillFlags['clear'] then
        slotsPattern = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
      else
        -- Just work with items we have inside
        slotsPattern = ptrn
      end
    end
  end

  -- Searching if wee have needed item in inventory
  local findInSlotsArrayByPattern = function (arr, n, blacklist)
    for i=1, 16 do
      if not blacklist[i] and arr[i] == n and (turtle.getItemCount(i) > 0) then
        return i
      end
    end
    return 0
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
        if slotWithBlock ~= 0  then
          fillGoToFnc(x,y,z)
          if orient then Turtle.setOrient(orient) end -- Can be nil - orientation don't matter
          
          -- We have block and can put it on place
          local placeSucces = Turtle.place(slotWithBlock, direct)
          
          if(placeSucces == true)then
            -- Block this cell in world, make it unable to go throught
            local blockPos = Turtle.getRelativeCoord(direct)
            Turtle.world:set(blockPos.x, blockPos.y, blockPos.z, true)
            
            -- Decrement block for placing
            totalBlockByIndexLeft[blockIndex] = totalBlockByIndexLeft[blockIndex] - 1
          end
         
          -- If slot was emptyed, we must note, that now there will be thrash
          -- Each next time when turtle dig, empty slot will filling
          if(turtle.getItemCount(slotWithBlock) == 0) then
            blacklistPattern[slotWithBlock] = true
            
            -- Check again if we have another slot with item
            if findInSlotsArrayByPattern(slotsPattern, blockIndex, blacklistPattern) == 0 and
              totalBlockByIndexLeft[blockIndex] > 0  then
              -- No avaliable blocks to build!
              -- Save coords, reload and return
              local stopPos = Turtle.pos:clone()
              
              reloadFnc()
              
              -- Go back to work
              Turtle.pathTo(stopPos)
            end
          end
        else
          -- Fatal fillError. We are probably reloaded, but still havent blocks to place
          -- This can happend only with bug in code
          fillError = 'Fatal Fill Error: No blocks to place on {'..x..','..y..','..z..'}. I dont know what went wrong. '
          backToStartFnc(fillError)
        end
      else -- blockIndex == 0
        -- Remove block here and do nothing
        local blockPos = fillGetPos(x,y,z) + (orient and surround[orient] or surround[direct])
        if not clearedPionts(blockPos:unpack()) then
          fillGoToFnc(x,y,z)
          if orient then Turtle.setOrient(orient) end -- Can be nil - orientation don't matter
          
          -- Choose action method
          if fillFlags['ore'] then
            Turtle.mine(direct)
          elseif fillFlags['lava'] then
            Turtle.place(1, direct, true)
            turtle.select(1)
            turtle.refuel()
            -- TODO: Fully refueled event
            --if turtle.getFuelLevel()>= turtle.getFuelLimit() then
            --  backToStartFnc("Turtle is complitely refueled!")
            --  os.reboot()
            --end
          else
            Turtle.dig(direct)
          end
          
          -- We cleared this point, so add to list
          clearedPionts:set(blockPos.x,blockPos.y,blockPos.z, true)
              
          -- If we should be greedy, chech we have free slots. And, free cargo if we havent
          if fillFlags['greedy'] then
            local noFreeSlots = true
            for i=1,16 do
              if turtle.getItemCount(i) < 1 then
                noFreeSlots = false
                break
              end
            end
            
            -- We have no free slots! Need to drop some items.
            if noFreeSlots then            
              -- If we dropped nothing or dropped only 1 block, go to start and drop there
              if dropIfTidy() <= 1 then
                -- Save coords, reload and return
                local stopPos = Turtle.pos:clone()
                
                -- Honestly, we not really reloading. Just clearing items in black list
                for i=1,16 do
                  blacklistPattern[i] = (slotsPattern[i]>0 and blacklistPattern[i] or 1)
                end
                reloadFnc()
                  
                -- Go back to work
                Turtle.pathTo(stopPos)
              end
            end
          end
        end
      end
    until not fillError
    
    return nil
  end -- fillFnc()

  
  
  -- Check bucked if we are refueling from lava
  if fillFlags['lava'] then
    while true do
      turtle.select(1)
      local data = turtle.getItemDetail()
      if not data or not (data.name == "minecraft:bucket" or data.name == "minecraft:lava_bucket") then
        backToStartFnc("Place a bucket in first slot and press ANY KEY")
      else
        break
      end
    end
    
    -- And try to suck firs bucket from down
    Turtle.place(1, way.DOWN, true)
    turtle.refuel()
  end
  
  

  -- ==============================
  -- Iterators
  -- ==============================
  
  -- move to start position
  fillGoToFnc(0, 0, ((sizeZ>1) and 1 or 0))
  
  -- forth is printing method, when we fill from us to forward
  if     fillFlags['forth'] then
    for _y=0, sizeY-1 do
      for _z=0, sizeZ-1 do
        for _x=0, sizeX-1 do
          local x,y,z = _x,_y,_z
          local placeWay = way.DOWN
          local shift = 1
          
          -- Ping-pong
          if not fillFlags['up'] and not fillFlags['down'] then
            if(y%2==1) then z = sizeZ-z-1; x = sizeX-x-1; placeWay=way.UP; shift=-1 end
          end
          if(z%2==1) then x = sizeX-x-1 end
          
          if fillFlags['up'] then
            fillFnc(x,y,z-1, way.UP, nil, vol[z][y][x])
          elseif fillFlags['down'] then
            fillFnc(x,y,z+1, way.DOWN, nil, vol[z][y][x])
          else
            fillFnc(x,y,z+shift, placeWay, nil, vol[z][y][x])
          end
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
          
          if  fillFlags['up'] then
            fillFnc(x,y,z-1, way.UP, nil, vol[z][y][x])
          else
            fillFnc(x,y,z+1, way.DOWN, nil, vol[z][y][x])
          end
        end
      end
    end
    
  -- And most awesome and fast filling method
  -- It filling 3 blocks per move
  else
    local zStepsCount    = math.ceil(sizeZ/3)-1 -- Count of levels, where robot moves horisontally
    local lastZStepIsCap = (sizeZ%3 == 1) -- The top level of volume is last level where turtle moves hor-ly
    local zLastStepLevel = zStepsCount*3+(lastZStepIsCap and 0 or 1) -- Z level where turtle will move last
    local boostMode = stats.totalBlockByIndex[0] == stats.totalBlocksToPlace -- clear all
    local yFirst = (sizeY > sizeX) -- We will go to Y coords first, then to next X
    local yBoost = boostMode and yFirst
    local size_v, size_w = sizeY-1, sizeX-1
    fillGoToFnc = _fillPathToFnc
    
    
    if yBoost then
      size_v, size_w = size_w, size_v
    end
    
    
    for _z=0, zStepsCount do
      for v=0, size_v do
        for w=0, size_w do
          local z = _z*3+1
          local currZStepIsLast = (_z==zStepsCount)
          if currZStepIsLast then z = zLastStepLevel end -- Cap of volume
          
          
          -- Ping-pong
          local currZIsEven = (_z%2==0)
          local horisontDirect = way.BACK -- Specific orientation, when we move to next Y pos
          local horisontShift  = -1       -- Y direction, when we move to next Y pos
          local x,y = w,v
          
          if boostMode then
            if yFirst then
              x,y = v, w
              if(_z%2==1) then y = sizeY-y-1; x = sizeX-x-1 end
              if(x%2==1)  then y = sizeY-y-1 end
            else
              if(_z%2==1) then y = sizeY-y-1; x = sizeX-x-1 end
              if(y%2==1)  then x = sizeX-x-1 end
            end
            
            -- Fill down
            if z>0 then
              fillFnc(x,y,z, way.DOWN, nil, vol[z-1][y][x])
            end
            -- Fill UP
            if z<sizeZ-1 then
              fillFnc(x,y,z, way.UP, nil, vol[z+1][y][x])
            end
          else
            if not currZIsEven then
              y = sizeY - y - 1
              horisontDirect = way.FORWARD
              horisontShift = 1
            end
            x = sizeX - x - 1 -- Revert X coordinates. Filling will be from right to left
            
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
            
            -- Move up and fill bocks down, if we advance to next Z level
            if hereWeWillGoUp then
              local nextZLevel = (_z+1)*3 + 1
              if lastZStepIsCap and (_z+1==zStepsCount) then nextZLevel = nextZLevel-1 end -- Cap of volume
              if not escapeShaftHere then
                for zAdvance=z+1, nextZLevel do
                  fillFnc(x,y,zAdvance, way.DOWN, nil, vol[zAdvance-1][y][x])
                end
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
    
    -- And last block
    fillFnc(0, -1, 0, way.FORWARD, way.FORWARD, vol[0][0][0])
  end
  
  -- Drop thrash if need
  dropIfTidy()
  
  -- Drop all mined items
  if fillFlags['greedy'] then
    -- Honestly, we not really reloading. Just clearing items in black list
    blacklistPattern = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
    reloadFnc()
  end
  
  -- ==============================
  -- Finishing
  -- ==============================
  
  -- Now we finished filling territory. Just go home
  if isGoBackAfterFill == true then
    -- Spread message then we want die
    if fillFlags['dock'] then Turtle.touch(touch["killMe"], -1) end
    
    -- And go to start pos to not interrupt others
    goThruGangway("startPos")
    Turtle.setOrient(way.FORWARD)
  end
  
  return true
end


--===========================================================
-- Dock building
--===========================================================
function jobs.createDock(maxSize)
  -- Select turtle from inventory, or suck from down
  local selectTurtleFnc = function()
    if not Turtle.select("Turtle", true) then
      if not turtle.suckUp() then return false end
      return Turtle.select("Turtle", true)
    end
    return true
  end
  
  -- Show box that we placing turtles
  KUI.setWindow({{ id='makeDock', type='textPanel', text='Placing turtles\nPlease click on\neach placed turtle', x=8,y=scrH/2-3, w=scrW-16,h=6}})
  
  -- Set redstone signal to avoid comebacking
  Turtle.setOrient(way.FORWARD)
  redstone.setOutput('front', true)
  
  -- Place turtles in front till all will be placed
  -- Loop untill we have turtles sucked from chest
  local slavesCount = 0
  while slavesCount < maxSize-1 and selectTurtleFnc() do
    -- Place turtle in front
    KUI.setWindow({{ id='placeTrtl', type='textPanel', text='Placing one turtle...', x=8,y=scrH/2-3, w=scrW-16,h=6}})
    while not Turtle.place(nil, nil, true) do sleep(1) end
    
    -- Turn on this slave
    while not pcall(peripheral.call,'front','turnOn') do sleep(0.5) end
    
    -- Add this turtle in slave list
    -- Loop until turtle will be activated and send message
    KUI.setWindow({{ id='placeTrtl', type='textPanel', text='Adding turtle\nto list...', x=8,y=scrH/2-3, w=scrW-16,h=6}})
    swarm.addSlave()
    
    slavesCount = slavesCount + 1
    
    -- Transmit location correction to older turtles
    KUI.setWindow({{ id='placeTrtl', type='textPanel', text='Send shift task to all', x=8,y=scrH/2-3, w=scrW-16,h=6}})
    swarm.transmitTask(nil, {name='rightShift'}, true)
  end
  
  -- Put turtles back
  -- TODO: Working with more chests sides
  while Turtle.selectNonEmptySlot() do turtle.dropUp() end
  
  redstone.setOutput('front', false)
  
  -- Move like we are the boss
  Turtle.setPos(0,-1,0)
  Turtle.goTo(0,0,0)
  
  return slavesCount
end


--===========================================================
-- Dock disassembling
--===========================================================
function jobs.disassembleDock(slavesCount)  
  KUI.setWindow({{ id='destroyDock', type='textPanel', text='Waiting all\nturtles go home...', x=8,y=scrH/2-3, w=scrW-16,h=6}})
  
  if Turtle.pos ~= vec3() then Turtle.goTo(0,0,0) end
  Turtle.goTo(0,-1,0)
  Turtle.setOrient(way.FORWARD)

  local slavesPicked = 0
  while slavesPicked < slavesCount do
    for i=1, slavesCount do
      swarm.transmitTask(i, {name='disassemble'})
    end
    
    -- Wait before someone throw kill request
    local strenght = Turtle.sense(way.FORWARD, 1)
    --local receivedObj = swarm.receiveFromSlave(1)
    
    --if receivedObj and receivedObj.name == "PleaseKillMe" then
    if strenght == touch["killMe"] then
      Turtle.dig()
      if Turtle.select("Turtle", true) then
        if not turtle.dropUp() then turtle.dropDown() end
        
        slavesPicked = slavesPicked + 1
      end
    end
  end
end
