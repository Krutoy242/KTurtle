-- ********************************************************************************** --
-- **   Main file of KrutoyTurtle program                                          ** --
-- **                                                                              ** --
-- **   User interface, fill algirithm code.                                       ** --
-- **                                                                              ** --
-- ********************************************************************************** --


------------------------------------------------------
-- Filling function variables                       --
------------------------------------------------------

-- Main patterns, using in jobs.fill() function
--  Numbers tell what the count block will be placed
--  Exists: fillPattern[name][z][y][x]
--  [space]: here will no block
--  0: remove block here
fillPattern = {
  ['Plain'] =
  { {{1}} },
  ['BoxGrid'] =
  { {{3, 2, 2, 2},
     {2, 1, 1, 1},
     {2, 1, 1, 1},
     {2, 1, 1, 1}},
    {{2, 1, 1, 1},
     {1},
     {1},
     {1}},
    {{2, 1, 1, 1},
     {1},
     {1},
     {1}},
    {{2, 1, 1, 1},
     {1},
     {1},
     {1}}},
}


-- List of avaliable flags
local avaliableFlags = {
  "hollow",         -- Only box without bulk
  "sides",          -- Making boxes without corners
  "corners",        -- Making frames
  "mirror",         -- Pattern texture will mirrored
  "mirror -1",      -- Each mirrored pattern indexes will shif by one block
  "mirror -1x",
  "mirror -1y",
  "mirror -1z",
  "x++", "x--",       -- Shift next coord. Userful for stairs
  "y++", "y--",
  "z++", "z--",
  "wash",           -- Replaces all nil to 0
  "skip",           -- Replaces all 0 to nil
  "tunnel", "tube", -- tunnel without caps on start end end
  "dense",          -- Chest for item every 1 block

  -- Flags changing fill iterator functions
  "forth",          -- Build first x-z blocks, then go to next y layer
  "printer",        -- Iterate block placing like printer
  "down",           -- Place all blocks down. Works with "printer" or "forth"
  "up",             -- Place all blocks up.   Works with "printer" or "forth"

  -- Flags for "plain" pattern
  "clear",          -- Replaces all pattern indexes to -1
  "greedy",         -- Save all items, putting them left ches
  "mine",           -- Duplicate tags clear+greedy
  "ore",            -- Duplicate "mine" but will crush only not cobble, dirt, gravel
  "tidy",           -- When inventory is full drops all thrash
  "lava",           -- Using bucket from first slot and refuels from it. Adds "clear"
}


------------------------------------------------------
-- Other variables                                  --
------------------------------------------------------

-- Enumeration to store names for the 6 directions
local way = { FORWARD=0, RIGHT=1, BACK=2, LEFT=3, UP=4, DOWN=5 }
local wayName = { [0]='Forward', ' Right', 'Back', 'Left', 'Up', 'Down'}

local MAXTURTLES = 128 -- Maximum amount of turtles in swarm
local idle = false     -- Turtle is idle and will be moved when something ask get out
local fillParamFile = "Krutoy/fillParams" -- Path to file with all fill parameters
local scrW, scrH = term.getSize() -- Get screen params
local serchOwnerThread, interfaceThread
local KTurtle_source = "http://pastebin.com/raw.php?i=g2ZqawdP"

local args = { ... }

local surround = {
[way.FORWARD] = vec3( 0, 1, 0),
[way.RIGHT]   = vec3( 1, 0, 0),
[way.BACK]    = vec3( 0,-1, 0),
[way.LEFT]    = vec3(-1, 0, 0),
[way.UP]      = vec3( 0, 0, 1),
[way.DOWN]    = vec3( 0, 0,-1)
}

------------------------------------------------------
-- Debug in IDE                                     --
------------------------------------------------------
IDE = (term==nil) and true or false
--[[
if IDE then
  loadfile('CC_emulator.lua')()
end

local function BREACKPOINT()
  print("DEBUG")
  while true do
    local dbgFnc = setfenv(loadstring(read()), getfenv(1))
    local status, err = pcall(dbgFnc)
    if err then print(); print(err) else return end
  end
end]]


-- ################################################################################## --
-- ##                                Utilities                                     ## --
-- ################################################################################## --

--===========================================================
-- Read user input and separate into table
--===========================================================
local function readTable(separator)
  local resultStr = read()
  if resultStr ~= '' then
    local result = {}
    for v in string.gmatch(resultStr, separator) do
      insert(result,v)
    end
    return result
  end
  return nil
end

-- ################################################################################## --
-- ##                            Startup functions                                 ## --
-- ################################################################################## --

-- ==============================
-- Auto-update
-- Download and replace running file
-- ==============================
local function autoUpdate()
  -- Get version of last
  if not http then return end
  local httpResponce = http.get(KTurtle_source)
  local allText = httpResponce.readAll()
  httpResponce.close()

  local newVersion = 0
  local _,verPos = string.find(allText, 'K_VERSION *= *')
  if verPos then
    newVersion = tonumber(string.match(allText, '%d+[%.?%d*]*', verPos+1))
  end

  -- Compare and replace
  if K_VERSION < newVersion then
    local sFile = shell.getRunningProgram()
    local f = fs.open(sFile, "w")
    f.write(allText)
    f.close()
    clearScreen()
    print("New version downloaded!")
    print("Rebooting to apply changes...")
    sleep(0.1)
    os.reboot()
    sleep(10)
  end
end

local function radiateRedstone(val)
  for k,v in pairs(redstone.getSides()) do
    redstone.setOutput(v, val)
  end
end

local function waitingInHarbor()
  -- Also, turn on nearest turtles
  Turtle.turnRight()
  -- Set redstone signal to nearest turtles
  radiateRedstone(true)
  pcall(peripheral.call,'front','turnOn')
  pcall(peripheral.call,'back' ,'turnOn')
end

local function leaveHarbor()
  -- Clear redstone signals
  radiateRedstone(false)
end


local function workInTeamSetup(leftShift)
  local harborHeight = 2
  local maxWidth = 256
  Turtle.setBeacon("storageStart", leftShift, 0, 0)
  Turtle.addForbiddenWayZone(way.LEFT,  way.UP,   leftShift+1,0,0, leftShift+maxWidth,0,0)
  Turtle.addForbiddenWayZone(way.RIGHT, way.DOWN, leftShift  ,0,1, leftShift+maxWidth,0,1)

  Turtle.addAlterZone(way.UP,    leftShift+1,0,1, leftShift+maxWidth,0,harborHeight)
  Turtle.addAlterZone(way.RIGHT, leftShift  ,0,0, leftShift+maxWidth,0,0)

  Turtle.addSafeZone(leftShift,0,0, leftShift+maxWidth+1,0,harborHeight)

  -- Block for path finding back wall and volume over harbor
  Turtle.world:setVolume(leftShift-1, -1, 0, leftShift+maxWidth+1, 0, 128, true)
  Turtle.world:setVolume(leftShift  ,  0, 0, leftShift+maxWidth  , 0, harborHeight, nil)
end



local function setupCommunications()
  -- Send message to neiborhoods to get out from way
  Turtle.onMoveAttempt = function(attempt, newX, newY, newZ, direction)
    if attempt > 2 and newY==0 then
      local _,data = Turtle.inspect(direction)
      if data and data.name and data.name:find("Turtle") then
        swarm.touch("getout", direction)
      end
    end
  end

  -- Get out
  thread.create(function()
    while true do
      local feelings = swarm.sense(-1)
      if feelings == "getout" and idle then -- -1 means from all sides
        -- Seems like we distracting someone.
        -- Just move up and let him go
        local oldPos = Turtle.pos:clone()
        local oldOrient = Turtle.orient
        Turtle.up()
        sleep(1)
        if idle then Turtle.goTo(oldPos); Turtle.setOrient(oldOrient) end
      end
    end
  end)
end


-- ==============================
-- Slave behavior
-- Manage slave actions
-- ==============================
local slaveBehavior = function()
  local distToOwner

  while true do
    distToOwner = swarm.searchOwner()

    -- Kill other thread
    thread.kill(interfaceThread)

    leaveHarbor()

    -- Owner is found. Show this on screen
    KUI.setWindow({{ id='slaveLabel', type='textPanel', text='This turtle\nis slave.\n\nWaiting orders.',
            x=8,y=scrH/2-3, w=scrW-16,h=6}})

    -- This turtle is slave. Waiting orders and run them
    local fillParams
    local firstShift = true

    -- loop for orders from master
    while true do

      idle = true
      local orderFromOwner = swarm.waitOrders()
      idle = false

      if not orderFromOwner then

      elseif orderFromOwner.name == 'disassemble' then
        -- Just go home and spam request to be picked up
        while true do
          Turtle.goTo("storageStart")
          Turtle.setOrient(way.BACK)
          swarm.touch("killMe")
          sleep(0.5)
        end

      elseif orderFromOwner.name == 'rightShift' then
        -- If this turtle is fresh, suck fuel from down and refuel
        while Turtle.isLowFuel() do
          clearScreen()
          print("Need Fuel! Please place in first slot or in chest under me.")
          Turtle.selectEmptySlot()
          turtle.suckDown()
          turtle.refuel()
        end

        if not firstShift then distToOwner = distToOwner+1 end
        firstShift=false

        -- Correct the location
        Turtle.setPos(-1,0,0)
        Turtle.goTo(0,0,0)

      elseif orderFromOwner.name == 'fillOptions' then
        fillParams = orderFromOwner

        if turtle.getFuelLevel() <= fillParams.stats.totalFuelNeeded then
          -- Turtle have not anought fuel. It must send this to owner.
          swarm.transmitToMaster({name='ERROR'})

          -- Run refuel loop till be fueled
          while turtle.getFuelLevel() < fillParams.stats.totalFuelNeeded do
            clearScreen()
            print("Need Fuel! Please place fuel in turtle to consume...")
            print()
            for i=1,16 do
              turtle.select(i)
              turtle.refuel()
            end
          end
        end

      elseif orderFromOwner.name == 'lash' then
        -- IMPORTANT:
        -- We changing self-position to turtle. It will think that we standing in negative coords
        Turtle.setPos(-fillParams.shift.x + distToOwner, Turtle.pos.y, Turtle.pos.z)
        workInTeamSetup(-fillParams.shift.x)

        -- Fill
        jobs.fill(fillParams.volume,
            vec3(fillParams.pos.x, fillParams.pos.y, fillParams.pos.z),
            vec3(fillParams.size.x, fillParams.size.y, fillParams.size.z), fillParams.fillFlags, fillParams.stats)

        -- Leave work cycle with this master
        break
      end
    end
  end
end


-- ==============================
-- Resume
-- ==============================
local function resume()
  -- Check if resume required
  if not Turtle.loadData() then return end

  -- Refstone signal means we dont need to comeback
  for k,v in pairs(redstone.getSides()) do
    if redstone.getInput(v) then
      Turtle.removeData()
      return
    end
  end

  local waitAbortThread, startResumeThread
  local comebackBreack = true

  -- Wait if user press any key to abourt comeback
  local waitAbortFnc = function()
    clearScreen()
    print("Seems like turtle is restarting!")
    print("Press ANY KEY to abort.")
    print()
    pressAnyKey()

    thread.kill(startResumeThread)

    Turtle.removeData()
    comebackBreack = false
  end

  -- Wait 10 seconds and go to start
  local startResumeFnc = function()
    sleep(2)
    term.setCursorPos(scrW/2-7, scrH/2-1)
    print("Come back in:")
    for i=10,1 do
      sleep(2)
      term.setCursorPos(scrW/2-7, scrH/2-1)
      print(i)
    end
    sleep(2)

    thread.kill(waitAbortThread)

    clearScreen()
    print("Comebacking...")

    if Turtle.beacons and Turtle.beacons["storageStart"] and Turtle.beacons["startPos"] then
      workInTeamSetup(Turtle.beacons["storageStart"].x)
      if Turtle.pos.y > 0 then
        Turtle.goTo(Turtle.pos.x, Turtle.pos.y, 0)
        Turtle.goTo(0, 0, 0)
      end
      Turtle.goTo("startPos")
    end
    Turtle.setOrient(way.FORWARD)

    Turtle.removeData()
    comebackBreack = false
  end

  -- Lunch both threads and return only in case of resume solved
  startResumeThread = thread.create(startResumeFnc)
  waitAbortThread   = thread.create(waitAbortFnc)
  while comebackBreack do sleep(0.1) end
end

-- ################################################################################## --
-- ##                                   Main                                       ## --
-- ################################################################################## --
function main()

  -- If we loaded from disk, copy startup file onboard
  if fs.exists("disk/startup") and not fs.exists("startup") then
    fs.copy("disk/startup", "startup")
  end

  -- Update
  autoUpdate()

  -- Not matter working this turtle alone or with others,
  -- it should know how to communicate
  setupCommunications()

  -- Check and resume if required
  resume()


  -- Seems like we are in line on harbor now
  waitingInHarbor()

  -- ==============================
  -- Main menu
  -- Fill options
  -- ==============================
  local interfaceFnc = function()
    idle = true

    while true do
    local nextBtn = { id='btn_next', type='button',   text='Next>>',
        x=scrW-10,y=scrH,w=8,h=1, borderStyle='none'}

    local fillOptionsWindow = {}
    insert(fillOptionsWindow,{ id='optionsLabel', type='textPanel', text='Fill options',
        x=0,y=0, w=scrW+2,h=3})
    local inputSize = { id='btn_size', type='input',    text='',
        x=3,y=6, w=scrW-13,h=1, borderStyle='none', align='left', padding={0,0,0,9}}

    insert(fillOptionsWindow,{ id='btn_pattern', type='button', text='Pattern: ""',
        x=3,y=4, w=scrW-4,h=1, borderStyle='none', align='left'})
    insert(fillOptionsWindow,{ id='txt_size', type='text',    text='   Size: ',
        x=3,y=6, w=9,h=1, borderStyle='none', align='left'})
    insert(fillOptionsWindow, inputSize)
    insert(fillOptionsWindow,{ id='btn_flags', type='button',   text='  Flags: _',
        x=3,y=8, w=scrW-4,h=1, borderStyle='none', align='left'})
    insert(fillOptionsWindow,nextBtn)


      local sizeX,sizeY,sizeZ
      local pattern = nil
      local pos = vec3(0,1,0)
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
              if type(tonumber(s)) == "number" then
                insert(result,tonumber(s))
              end
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
          for k,_ in pairs(fillPattern) do insert(tmpPatternList, k) end
          for _,v in pairs(fs.list('')) do
            local fileExtension = string.sub(v,#v-3,#v)
            if fileExtension == '.vox' or fileExtension == '.nfa' and not fillPattern[v] then
              insert(tmpPatternList, v)
            end
          end

          -- Assemble string to show user and wait his choose
          local currLine = ''
          for k,v in pairs(tmpPatternList) do
            currLine = currLine..' '..k..' - '..v..'\n'
          end
          clearScreen()
          print(currLine)
          local result
          while true do
            local event, n = os.pullEvent("char")
            n = tonumber(n)
            if type(n) == 'number' and n >= 1 and n <= #tmpPatternList then
                result = n
              break
            end
          end

          -- Load needed files if we dont had them already
          local pattLen = tblLen(fillPattern)
          pattern = tmpPatternList[result]
          if result > pattLen then -- This pattern is file. Load File
            local fileExtension = string.sub(pattern,#pattern-3,#pattern)
            if fileExtension == '.nfa' then
              fillPattern[pattern],sizeX,sizeY,sizeZ = volumeLoader.load_nfa(pattern)
              inputSize.text = sizeX..' '..sizeY..' '..sizeZ
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
          local oldWnd = KUI.currentWindow

          KUI.setWindow({{ id='flags_label', type='textPanel',
            text='Add flags if need, separate\with commas, and press ENTER',
            x=1,y=0, w=scrW,h=4}})
          term.setCursorPos(5,7)
          local result = readTable("[%a%d]+")
          if result then
            fillFlags = makeSet(result)
            sender.text = '  Flags: '.. table.concat(result,", ")
          end

          KUI.setWindow(oldWnd, optionId)
        end

        if not pattern or not sizeX or not sizeY or not sizeZ then
          inputSize.text = (sizeX or '0')..' '..(sizeY or '0')..' '..(sizeZ or '0')
        end
        KUI.nextTab()
        helpTab = KUI.selectedObj.id
      end
      KUI.onKeyPressed = nil

      -- Kill searching thread
      thread.kill(serchOwnerThread)

      -- Parse negative numbers
      if sizeX < 0 then sizeX=math.abs(sizeX); pos.x=pos.x-sizeX end
      if sizeY < 0 then sizeY=math.abs(sizeY); pos.y=pos.y-sizeY end
      if sizeZ < 0 then sizeZ=math.abs(sizeZ); pos.z=pos.z-sizeZ end

      -- Volume of "owner" or "master" turtle
      local masterVolume, masterStats
      local gsize = vec3(sizeX,sizeY,sizeZ)
      local masterSize = gsize
      local wholeVlume, wholeStats = jobs.computeFillVolume(vec3(), gsize, gsize, fillPattern[pattern], fillFlags)

      -- ==============================
      -- Find other turtles
      -- ==============================
      local errorsArray = {}
      local slavesCount = 0


      -- Loop while no errors sended from turtles
      repeat

        -- If we have a dock, we need to place turtles one by one
        local alreadyHaveDock = false
        if fillFlags['dock'] then
          if not alreadyHaveDock then slavesCount = jobs.createDock(sizeX) end
          alreadyHaveDock = true
        else
          -- Show box that we waiting for slaves
          KUI.setWindow({{ id='findSlaves', type='textPanel', text='Trying to find slaves\nWait a sec...', x=8,y=scrH/2-3, w=scrW-16,h=6}})

          -- Broadcast message and get all responses
          slavesCount = swarm.findSlaves(MAXTURTLES/200)   ;if IDE then slavesCount = 1 end
        end

        if(slavesCount > 0) then
          KUI.setWindow({{ id='slavesFound', type='textPanel', text='Slaves found!\nSending orders...', x=8,y=scrH/2-3, w=scrW-16,h=6}})

          -- Slice whole wolume to equal stacks
          local slices = splitJob(wholeStats.shelfX, slavesCount+1)


          local partCursor = 0
          for i=0, slavesCount do
            local size      = vec3(slices[i+1], sizeY, sizeZ)
            local prt_shift = vec3(partCursor, 0, 0)
            partCursor = partCursor + slices[i+1]

            -- Get volume for this part
            local volumePart, statPart = jobs.computeFillVolume(prt_shift, size, gsize, fillPattern[pattern], fillFlags)

            if i==0 then
              -- This turtle is master and we have slaves
              masterSize = size
              masterVolume, masterStats = volumePart, statPart
              workInTeamSetup(0)
            else
              -- Prepare table with parameters for send
              local taskObj = {name='fillOptions', volume=volumePart, size={x=size.x,y=size.y,z=size.z},
                             shift={x=prt_shift.x,y=prt_shift.y,z=prt_shift.z}, pos={x=pos.x,y=pos.y,z=pos.z},
                             fillFlags=fillFlags, stats=statPart}

              swarm.transmitTask(i, taskObj)
            end
          end

          -- Show that we sended volumes and wait errors
          KUI.setWindow({{ id='waitingWhine', type='textPanel', text='Orders sended.\nWait problems if had...', x=8,y=scrH/2-3, w=scrW-16,h=6}})

          -- Make new array of errors
          errorsArray = {}
          local received = swarm.receiveFromSlave(slavesCount/100)
          while received do
            if received.name == "ERROR" then insert(errorsArray, received) end
            received = swarm.receiveFromSlave(slavesCount/100)
          end

          -- Show errors
          if #errorsArray > 0 then
            local whineArrayStr = ""
            for k,v in pairs(errorsArray) do
              whineArrayStr = whineArrayStr .. 'Turt #' .. v.slaveId .. ': ' .. v.message
            end
            KUI.setWindow({{ id='showWhine', type='textPanel', text='Huston!\n We have a problems:\n' .. whineArrayStr .. '\nPress ENTER', x=8, y=scrH/2-2, w=scrW-10,h=10}})
            read()
          end
        else -- slavesCount == 0
          Turtle.setBeacon("storageStart", 0, 0, 0)
          masterVolume, masterStats = wholeVlume, wholeStats
        end
      until #errorsArray == 0

      local needUseApprove = not fillFlags['dock']

      -- ==============================
      -- Info screen
      -- ==============================
      local infoText = ' INFO \n' ..
                       'Fuel level:            ' .. (masterStats.totalFuelNeeded <= turtle.getFuelLevel() and 'OK' or 'NOT ENOUGHT!!') .. '\n' ..
                       'Blocks by type:\n'

      -- Print how much we need of blocks by each type
      for k,v in ipairs(wholeStats.totalBlockByIndex) do
        local stacks   = floor(v/64)
        local modStacks= v%64
        infoText = infoText .. ' #'..k..': '..((stacks>0) and stacks..'x64' or '')..
          ((stacks>0 and modStacks>0) and ' + ' or '')..
          ((modStacks>0) and modStacks or '') .. '\n'
      end
      infoText = infoText ..'Press ENTER\n'


      KUI.setWindow({{ id='fillInfo', type='textPanel', text=infoText, x=1, y=1, w=scrW,h=scrH, align='left'}})
      if needUseApprove then read() end
      clearScreen()

      -- Lash slaves
      for i=1, slavesCount do
        swarm.transmitTask(i, {name='lash'})
      end

      leaveHarbor()

      idle = false
      jobs.fill(masterVolume, pos, masterSize, fillFlags, masterStats)

      -- Disassemble if we work with dock
      if fillFlags['dock'] then
        jobs.disassembleDock(slavesCount)
      end

      idle = true
    end
  end


  -- Do not show anything. Just wait if we had owner
  serchOwnerThread = thread.create(slaveBehavior)
  interfaceThread  = thread.create(interfaceFnc)

  -- Make look like we working.
  while true do sleep(999999) end

end

-- Function, called in start of all.
if IDE then main() end