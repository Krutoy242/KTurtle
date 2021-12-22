




-- 00_Readme.lua
-- ********************************************************************************** --
-- **                                                                              ** --
-- **   Krutoy Turtle 2.0  (debug version)                                         ** --
-- **   http://pastebin.com/g2ZqawdP                                               ** --
-- **   ----------------------------------------------------                       ** --
-- **                                                                              ** --
-- **   Run on turtle:                                                             ** --
-- **   pastebin get g2ZqawdP startup                                              ** --
-- **                                                                              ** --
-- **   Developing page:                                                           ** --
-- **   http://computercraft.ru/topic/48-stroitelnaia-sistema-krutoyturtle/        ** --
-- **                                                                              ** --
-- **   ----------------------------------------------------                       ** --
-- **   Thanks for this peoples, i use theirs code:                                ** --
-- **    - AustinKK (OreQuarry Turtle), NitrogenFingers (NPaintPro), ZeroGalaxy    ** --
-- **                                                                              ** --
-- ********************************************************************************** --


------------------------------------------------------
-- Fun                                              --
------------------------------------------------------

--[[
    ____
\  /o o \  /
 \|  ~   |/
   \____/

 ,+---+  ,+---+  ,+---+
+---+'| +---+'| +---+'|
|^_^| + |^_^| + |^_^| +
+---+'  +---+'  +---+'

]]--

K_VERSION = 2.049 -- Version of program. Need for auto-update





-- 03_Utils.lua



--===========================================================
-- Inline help functions
--===========================================================
local function clearScreen()     term.clear(); term.setCursorPos(1,1) end
local function tblLen(tbl)       local n=0;       for _,_  in pairs(tbl) do n = n + 1 end return n end
local function makeSet(list)     local set = {};  for _, v in pairs(list) do set[v] = true end return set end
local function pressAnyKey()     local event, param1 = os.pullEvent ("key") end
local function getChar(str, pos) return string.sub(str, pos, pos) end




-- ********************************************************************************** --
-- **   3D Vector                                                                  ** --
-- **                                                                              ** --
-- **   Modified version of 2d vector from                                         ** --
-- **   https://github.com/vrld/hump/blob/master/vector.lua                        ** --
-- **                                                                              ** --
-- **   By Krutoy242                                                               ** --
-- **                                                                              ** --
-- ********************************************************************************** --

vec3 = (function()
  local assert = assert
  local sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2

  local vector = {}
  vector.__index = vector

  local function new(...)
    local x,y,z = ...
    if type(x) == "table" then x,y,z = x.x, x.y, x.z end
    return setmetatable({x = x or 0, y = y or 0, z = z or 0}, vector)
  end
  local zero = new(0,0,0)

  local function isvector(v)
    return type(v) == 'table' and type(v.x) == 'number' and type(v.y) == 'number' and type(v.z) == 'number'
  end

  function vector:clone()
    return new(self.x, self.y, self.z)
  end

  function vector:unpack()
    return self.x, self.y, self.z
  end

  function vector:__tostring()
    return "("..tonumber(self.x)..","..tonumber(self.y)..","..tonumber(self.z)..")"
  end

  function vector.__unm(a)
    return new(-a.x, -a.y, -a.z)
  end

  function vector.__add(a,b)
    assert(isvector(a) and isvector(b), "Add: wrong argument types (<vector> expected)")
    return new(a.x+b.x, a.y+b.y, a.z+b.z)
  end

  function vector.__sub(a,b)
    assert(isvector(a) and isvector(b), "Sub: wrong argument types (<vector> expected)")
    return new(a.x-b.x, a.y-b.y, a.z-b.z)
  end

  function vector.__mul(a,b)
    if type(a) == "number" then
      return new(a*b.x, a*b.y, a*b.z)
    elseif type(b) == "number" then
      return new(b*a.x, b*a.y, b*a.z)
    else
      assert(isvector(a) and isvector(b), "Mul: wrong argument types (<vector> or <number> expected)")
      return a.x*b.x + a.y*b.y + a.z*b.z
    end
  end

  function vector.__div(a,b)
    assert(isvector(a) and type(b) == "number", "wrong argument types (expected <vector> / <number>)")
    return new(a.x / b, a.y / b, a.z / b)
  end

  function vector.__eq(a,b)
    return a.x == b.x and a.y == b.y and a.z == b.z
  end

  function vector.__lt(a,b)
    return a.x < b.x and a.y < b.y and a.z < b.z
  end

  function vector.__le(a,b)
    return a.x <= b.x and a.y <= b.y and a.z <= b.z
  end

  function vector.permul(a,b)
    assert(isvector(a) and isvector(b), "permul: wrong argument types (<vector> expected)")
    return new(a.x*b.x, a.y*b.y, a.z*b.z)
  end

  function vector:len2()
    return self.x * self.x + self.y * self.y + self.z * self.z
  end

  function vector:len()
    return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
  end

  function vector.dist(a, b)
    assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector> expected)")
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return sqrt(dx * dx + dy * dy + dz * dz)
  end

  function vector.dist2(a, b)
    assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector> expected)")
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return (dx * dx + dy * dy + dz * dz)
  end

  function vector:normalize_inplace()
    local l = self:len()
    if l > 0 then
      self.x, self.y, self.z = self.x / l, self.y / l, self.z / l
    end
    return self
  end

  function vector:normalized()
    return self:clone():normalize_inplace()
  end

  function vector:rotate_inplace_z(phi)
    local c, s = cos(phi), sin(phi)
    self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
    return self
  end
  function vector:rotate_inplace_x(phi)
    local c, s = cos(phi), sin(phi)
    self.y, self.z = c * self.y - s * self.z, s * self.y + c * self.z
    return self
  end
  function vector:rotate_inplace_y(phi)
    local c, s = cos(phi), sin(phi)
    self.z, self.x = c * self.z - s * self.x, s * self.z + c * self.x
    return self
  end

  function vector:rotated_z(phi)
    local c, s = cos(phi), sin(phi)
    return new(c * self.x - s * self.y, s * self.x + c * self.y, self.z)
  end
  function vector:rotated_x(phi)
    local c, s = cos(phi), sin(phi)
    return new(self.x, c * self.y - s * self.z, s * self.y + c * self.z)
  end
  function vector:rotated_y(phi)
    local c, s = cos(phi), sin(phi)
    return new(s * self.z + c * self.x, self.y, c * self.z - s * self.x)
  end

  function vector:cross(v)
    assert(isvector(v), "cross: wrong argument types (<vector> expected)")
    return new(self.Y * v.Z - self.Z * v.Y,
               self.Z * v.X - self.X * v.Z,
               self.X * v.Y - self.Y * v.X)
  end

  function vector:trim_inplace(maxLen)
    local s = maxLen * maxLen / self:len2()
    s = (s > 1 and 1) or math.sqrt(s)
    self.x, self.y, self.z = self.x * s, self.y * s, self.z * s
    return self
  end

  function vector:trimmed(maxLen)
    return self:clone():trim_inplace(maxLen)
  end


  -- the module
  return setmetatable({new = new, isvector = isvector, zero = zero},
  {__call = function(_, ...) return new(...) end})
end)()


-- ********************************************************************************** --
-- **   3D Array                                                                   ** --
-- **                                                                              ** --
-- **   By Krutoy242                                                               ** --
-- **                                                                              ** --
-- ********************************************************************************** --
arr3d = function() return setmetatable({
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
})end



--===========================================================
-- Devide giving space to parts
--===========================================================
local function splitJob(cargo, ...)
  local args = {...}
  assert(#args ~= 0, "Wrong splitJob parameters")

  local cargoCount = #args
  local arr = {}

  if type(cargo) == "number" and cargoCount==1 then
    -- We havent weights, just count of slots
    local slices = args[1]
    local intPart = floor(cargo/slices)
    local residue = cargo % slices
    for i=1,slices do
      insert(arr, intPart + (residue>=1 and 1 or 0))
      residue = residue - 1
    end
  elseif type(cargo) == "number" then
    -- We have weight array, devide by weight
    local fullWeight=0
    for i=1, #args do fullWeight = fullWeight+args[i] end
    local residue = cargo
    -- Give each slot weight 1
    for i=1, #args do
      insert(arr, 1)
      residue = residue - 1
    end
    local tmpResidue = residue
    -- Give each slot by weights
    for i=1, #args do
      local prtVal = floor(args[i]/fullWeight*tmpResidue)
      arr[i] = arr[i] + prtVal
      residue = residue - prtVal
    end
    -- Give last parts to most heavyes slots, if they will still not have enought
    local overage = fullWeight/cargoCount
    local optima = 1
    while residue>0 do
      for i=1,#args do
        if args[i]/arr[i] > args[optima]/arr[optima] then
          optima = i
        end
      end
      arr[optima] = arr[optima] + 1
      residue = residue - 1
      optima = (optima % #args) + 1
    end
  elseif type(cargo) == "table" then
    -- Each cargo have weight

    -- Make base 0 array
    if cargo[0] == nil then
      cargo[0] = cargo[1]
      table.remove(cargo,1)
    end

    local parts = args[1]
    local len = tblLen(cargo)
    local sum = {}
    local avg
    local T = {}; for i=1,len do T[i]={}end
    local K = {}; for i=1,len do K[i]={}end

    local penalty = function(a,b)
      local x = (sum[b]or 0) - (sum[a]or 0)
      x = x-avg
      return x*x
    end

    sum[0]=0
    for n=1, len do
      sum[n] = (sum[n-1]or 0) + (cargo[n-1]or 0)
    end
    avg = (sum[len]or 0)/parts

    for n=0, len do
      T[1][n] = penalty(0,n)
      K[1][n] = n
    end

    for m=2,parts do
      for n=0,len do
        T[m][n] = math.huge
        K[m][n] = -1
        for k=0,n do
          if (T[m][n]or 0) > (T[m-1][k]or 0) + penalty(k,n) then
            T[m][n] = (T[m-1][k]or 0) + penalty(k,n)
            K[m][n] = k
          end
        end
      end
    end


    for m=parts,2,-1 do
      local sep = K[m][len]
      arr[m] = len-sep
      len = sep
    end
    arr[1] = K[1][len]
  else
    error("Wrong splitJob parameters: cargo")
  end

  return arr
end





-- 05_KrutoyTurtle.lua
-- ********************************************************************************** --
-- **   Main file of KrutoyTurtle program                                          ** --
-- **                                                                              ** --
-- **   User interface, fill algirithm code.                                       ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- Redefine global function for faster acces
local floor = math.floor
local ceil  = math.ceil
local insert= table.insert
local min   = math.min
local max   = math.max


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
local KTurtle_sourse = "http://pastebin.com/raw.php?i=g2ZqawdP"

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
  local httpResponce = http.get(KTurtle_sourse)
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




local function workInTeamSetup(leftShift)
  local harborHeight = 4
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

  -- Get out
  thread.create(function()
    while true do
      swarm.waitGetout()
      if idle then
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
        -- Just go home
        Turtle.goTo("storageStart")
        -- And spam request to be picked up
        while true do
          swarm.transmitToMaster({name="PleaseKillMe"})
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

  -- Update on background
  autoUpdate()

  -- Check and resume if required
  resume()

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
              if type(tonomber(s)) == "number" then
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
          local oldWnd = KUI.currentWindow

          KUI.setWindow({{ id='flags_label', type='textPanel',
            text='Add flags if need, separate with commas, and press ENTER',
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

      idle = false
      jobs.fill(masterVolume, pos, masterSize, fillFlags, masterStats)
      idle = true

      -- Disassemble if we work with dock
      if fillFlags['dock'] then
        jobs.disassembleDock(slavesCount)
      end
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





-- 07_Jobs.lua


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
  for z,vy in pairs(pattern) do
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

  local isGoBackAfterFill = not fillFlags['dock']
  local slotsPattern
  local armedByIndex = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  Turtle.setBeacon("startPos", Turtle.pos:clone())

  -- Make array representing how much blocks each type we need to place
  -- Each time block placed value will be decremented
  local totalBlockByIndexLeft = {}
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
    if Turtle.pos.y > 0 then Turtle.pathTo(0,0,0) end
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


  -- Send message to neiborhoods to get out from way
  Turtle.onMoveAttempt = function(attempt, newX, newY, newZ, direction)
    if attempt > 2 and newY==0 then
      local _,data = Turtle.inspect(direction)
      if data and data.name and data.name:find("Turtle") then
        swarm.sendGetout()
        sleep(0.1)
      end
    end
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
            if turtle.getFuelLevel()>= turtle.getFuelLimit() then
              backToStartFnc("Turtle is complitely refueled!")
              shell.run("reboot")
            end
          else
            turtle.select(1) -- To sorting
            Turtle.dig(direct)
          end

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
    if Turtle.pos.y ~= 0 then
      fillGoToFnc(0, 0, 0)
      fillGoToFnc(0, -1, 0)
    end
    Turtle.goTo("startPos")
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
  redstone.setOutput('front', true)

  -- Place turtles in front till all will be placed
  -- Loop untill we have turtles sucked from chest
  local slavesCount = 0
  while slavesCount < maxSize-1 and selectTurtleFnc() do
    -- Place turtle in front
    KUI.setWindow({{ id='placeTrtl', type='textPanel', text='Placing one turtle...', x=8,y=scrH/2-3, w=scrW-16,h=6}})
    while not Turtle.place(nil, nil, true) do sleep(0.3) end

    -- Add this turtle in slave list
    -- Loop until turtle will be activated and send message
    KUI.setWindow({{ id='placeTrtl', type='textPanel', text='Addint turtle\nto list...', x=8,y=scrH/2-3, w=scrW-16,h=6}})
    swarm.addSlave()

    slavesCount = slavesCount + 1

    -- Transmit location correction to older turtles
    for i=1, slavesCount do
      -- Prepare table with parameters for send
    KUI.setWindow({{ id='placeTrtl', type='textPanel', text='Send shift task to '..i, x=8,y=scrH/2-3, w=scrW-16,h=6}})
      swarm.transmitTask(i, {name='rightShift'}, true)
    end
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
    local receivedObj = swarm.receiveFromSlave(1)

    if receivedObj and receivedObj.name == "PleaseKillMe" then
      Turtle.dig()
      if Turtle.select("Turtle", true) then
        if not turtle.dropUp() then turtle.dropDown() end

        slavesPicked = slavesPicked + 1
      end
    end
  end
end






-- 10_KTurtle.lua
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

local attemptsToAlternative = 10
local attemptsToFailure = 15
local attemptsToIndicate = 20

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
      --Loading in the data since nothig bad happened
      Turtle.pos    = vec3(data.x, data.y, data.z)
      Turtle.orient = data.orient
      Turtle.moving = data.moving

      Turtle.beacons = data.beacons
      for k,v in pairs(Turtle.beacons) do
        Turtle.beacons[k] = vec3(v)
      end

      if data.fuel == currentFuel+1 then
        --Here, we've gotta fix a few things since the turtle did in fact, move
        Turtle.setPos(Turtle.getRelativeCoord(Turtle.moving))
      end

      -- Indicate that we are resuming
      return true
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





-- 20_KUI.lua
-- ********************************************************************************** --
-- **   UI class for program "KrutoyTurtle"                                        ** --
-- **                                                                              ** --
-- ********************************************************************************** --

--[[
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░_____________Final info______________░
░-Slaves:      64                     ░
░-Total Volume:30000                  ░
░-Est. time:   90 min                 ░
░-More info:   bla bla                ░
░___________Blocks by type____________░
░#1 : 99s+50  #2 : 99s+50  #3 : 99s+50░
░#4 : 99s+50  #5 : 99s+50  #6 : 99s+50░
░#7 : 99s+50  #8 : 99s+50  #9 : 99s+50░
░#10: 99s+50  #11: 99s+50  #12: 99s+50░
░#13: 99s+50  #14: 99s+50  #15: 99s+50░
░#16: 99s+50  #16: 99s+50  #16: 99s+50░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░                                     ░
░           KRUTOY TURTLE             ░
░_____________________________________░
░ Fill options:                       ░
░                                     ░
░  Pattern: Plain                     ░
░     Size: 5 5 6                     ░
░    Flags: mine, tidy, dock          ░
░                                     ░
░Help:                                ░
░ Navigate - TAB, arrows              ░
░ Refuel - R, Console - ~     [Next>>]░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░__________Select pattern:____________░
░ 1 - Plain                           ░
░ 2 - BoxGrid                         ░
░ 3 - MyFirstTample.vox               ░
░                                     ░
░                                     ░
░                                     ░
░                                     ░
░                                     ░
░                                     ░
░                                     ░
░                                     ░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░


]]

KUI = {}
KUI.__index = KUI

local sub = string.sub

local borderStylesStr = {
  ['selectedBtn']= '/\\/\\  ||',
  ['standart']   = '++++--||',
  ['none']       = '        ',
  ['inlineBtn']  = '[]][    '
}
-- Transform string to array
local borderStyles = {}
for k,v in pairs(borderStylesStr) do
  borderStyles[k] = {}
  local styleStr = v
  for i = 1, #styleStr do
    borderStyles[k][i] = (styleStr:sub(i,i))
  end
end


local alignTypes = {'left', 'right', 'center'}

KUI.items = {} -- Array of UI elements
KUI.selectedObj = nil -- Currently selected item
KUI.currentWindow = nil -- Current drawing window



-- Repeat char many as need times to make string
local function repeatChar(char, count)
  local returnString = ''
  for _=0, count-1 do
    returnString = returnString..char
  end
  return returnString
end


function KUI.drawText(text, x,y, w,h, align)
  align = align or 'center'

  -- String params
  local textLinesCount = 1 + select(2, text:gsub('\n', '\n'))

  -- Top spaces
  local vertSpace = (h-textLinesCount)/2
  local clearLine = repeatChar(' ', w)
  for _=1, math.floor(vertSpace) do
    term.setCursorPos(x, y)
    term.write(clearLine)
  end

  -- Bottom spaces
  for _=1, math.ceil (vertSpace) do
    term.setCursorPos(x, y+h-1)
    term.write(clearLine)
  end

  -- Write lines
  local currLine = 0
  for l in text:gmatch('[^\r\n]+') do
    local margin = {0,0} -- Spaces from left and right
    local horisSpace = (w - #l)

    -- Align styles
    if    (align == 'left') then
      margin = {0, horisSpace}
    elseif(align == 'right')then
      margin = {horisSpace, 0}
    elseif(align == 'center')then
      margin = {math.floor(horisSpace/2), math.ceil(horisSpace/2)}
    end

    term.setCursorPos(x, y+currLine)
    term.write( repeatChar(' ',margin[1])..l..repeatChar(' ',margin[2]))
    currLine = currLine+1
  end
end

-- Draw simple panel with borders
function KUI.drawPanel(x,y, w,h, borderStyle)
  borderStyle = borderStyle or 'standart'
  local styleArr = borderStyles[borderStyle]

  -- Horisontal lines
  if(h > 1) then
    term.setCursorPos(x, y)
    term.write(styleArr[1]..repeatChar(styleArr[5], w-2)..styleArr[2])
    term.setCursorPos(x, y+h-1)
    term.write(styleArr[4]..repeatChar(styleArr[6], w-2)..styleArr[3])
  elseif h==1 then
    term.setCursorPos(x, y);     term.write(styleArr[1])
    term.setCursorPos(x+w-1, y); term.write(styleArr[2])
  end

  -- Vertical lines
  for i=0,h-3 do
    term.setCursorPos(x, y+i+1)
    term.write(styleArr[7])
    term.setCursorPos(x+w-1, y+i+1)
    term.write(styleArr[8])
  end

end

-- Draw panel with text
function KUI.drawTextPanel(text, x,y, w,h, borderStyle, align)
  KUI.drawPanel(x,y, w,h, borderStyle)

  if borderStyle == 'none' then
    KUI.drawText(text, x,y+((h>1) and 1 or 0), w,h, align)
  else
    KUI.drawText(text, x+1,y+((h>1) and 1 or 0), w-2,h, align)
  end
end

-- ********************************************************************************** --
-- Add gui element to current window
-- ********************************************************************************** --
function KUI.add(obj)
  -- Standart values
  obj.borderStyle = obj.borderStyle or 'standart'
  obj.align       = obj.align       or 'center'
  obj.padding     = obj.padding     or {0,0,0,0}

  -- Add additional info
  obj.center = {x=obj.x+obj.w/2, y=obj.y+obj.h/2}

  obj.nextTab = KUI.items[1] or obj
  if(#KUI.items >= 1) then
  KUI.items[#KUI.items].nextTab = obj
  end

  if obj.type == 'button' or obj.type == 'input' then
    obj.selectable = true
  end

  table.insert(KUI.items, obj)
end

-- ********************************************************************************** --
-- Set new window. Add all objects in list to screen
-- ********************************************************************************** --
function KUI.setWindow(window, selectedId)
  KUI.items = {}
  KUI.selectedObj = nil
  KUI.currentWindow = window
  for _,obj in pairs(window) do
    KUI.add(obj)

    if obj.id == selectedId then KUI.selectedObj = obj end
  end
  KUI.selectedObj = KUI.selectedObj or KUI.items[1]
  KUI.draw()
end

-- ********************************************************************************** --
-- Clears screen and write message in center
-- ********************************************************************************** --
function KUI.msgBox(str)

end

-- ********************************************************************************** --
-- Draw all objects in list
-- ********************************************************************************** --
function KUI.draw()
  term.clear()
  for _,obj in pairs(KUI.items) do

    -- Switch type
    if     obj.type == 'panel' then
      KUI.drawPanel(obj.x,obj.y, obj.w,obj.h, obj.borderStyle)
    elseif obj.type == 'text' then
      KUI.drawText(obj.text,
        obj.x+obj.padding[4],
        obj.y+obj.padding[1],
        obj.w-obj.padding[2]-obj.padding[4],
        obj.h-obj.padding[1]-obj.padding[3],
        obj.align)
    elseif obj.type == 'textPanel' or obj.type == 'button' or obj.type == 'input' then
      KUI.drawTextPanel(obj.text,
        obj.x+obj.padding[4],
        obj.y+obj.padding[1],
        obj.w-obj.padding[2]-obj.padding[4],
        obj.h-obj.padding[1]-obj.padding[3],
        obj.borderStyle, obj.align)
    else

    end

    -- This object is selected and selectable
    if KUI.selectedObj == obj and obj.selectable == true then
      KUI.drawPanel(obj.x-1,
                    obj.y,
                    obj.w+2+obj.padding[2]+obj.padding[4],
                    obj.h  +obj.padding[1]+obj.padding[3], 'inlineBtn')
    end

  end

  -- Set Cursor
  local selObj = KUI.selectedObj
  if selObj.type == 'input' then
    term.setCursorPos(selObj.x+selObj.padding[4]+#selObj.text, selObj.y+selObj.padding[1])
    term.setCursorBlink(true)
  else
    term.setCursorBlink(false)
  end

  sleep(0)
end

function KUI.navigate()
  while true do
    local e, keyCode = os.pullEvent('key')

    -- Call user-defined event
    if KUI.onKeyPressed then KUI.onKeyPressed(keyCode) end

    -- Input line
    local selObj = KUI.selectedObj
    if selObj ~= nil and selObj.type == 'input' then
      local keyMap = {"",1,2,3,4,5,6,7,8,9,0,"-",[57]=" "}
      if keyMap[keyCode] ~= nil then
        selObj.text = selObj.text .. keyMap[keyCode]
        KUI.draw()
      elseif keyCode == 14 then -- BACKSPACE
        selObj.text = selObj.text:sub(1,#selObj.text-1)
        KUI.draw()
      end
    end

    if     keyCode == 200 then --UP
      KUI.prevTab()
    elseif keyCode == 203 then --LEFT

    elseif keyCode == 205 then --RIGHT

    elseif keyCode == 15 or keyCode == 208 then --TAB --DOWN
      KUI.nextTab()
    elseif keyCode == 28  then --ENTER
      if selObj ~= nil then
        return selObj.id, selObj
      end
    end
  end
end

function KUI.nextTab()
  local oldSelectedObj = KUI.selectedObj
  KUI.selectedObj = KUI.selectedObj.nextTab
  while KUI.selectedObj.selectable ~= true and oldSelectedObj ~= KUI.selectedObj do
    KUI.selectedObj = KUI.selectedObj.nextTab
  end
  KUI.draw()
end

function KUI.prevTab()
  local oldSelectedObj = KUI.selectedObj
  local nextTab = KUI.selectedObj.nextTab
  local lastSelectable = (nextTab.selectable == true) and nextTab or oldSelectedObj
  while oldSelectedObj ~= nextTab.nextTab do
    nextTab = nextTab.nextTab
    if nextTab.selectable == true then lastSelectable = nextTab end
  end
  KUI.selectedObj = lastSelectable
  KUI.draw()
end





-- 30_Swarm.lua
-- ********************************************************************************** --
-- **   ZeroSwarm                                                                  ** --
-- **   with help from ZeroGalaxy                                                  ** --
-- **   ----------------------------------------------------                       ** --
-- **                                                                              ** --
-- **   Swapping messages with turtles to make band                                ** --
-- **   for KrutoyTurtle                                                           ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- Looks like a class
swarm = {}
swarm.__index = swarm

-- Locals
local CHANNEL_BROADCAST = 65535
local CHANNEL_REPEAT = 65533
local modemOpened = false
local MASTERMESSAGE = 'I AM YOUR MASTER. OBEY!'
local GETOUTMESSAGE = 'GET OUT!'
local CONFIRMMESSAGE= 'CONFIRM'
local masterId
local slaves = {}
local modem
local uniqueID = math.floor(os.time()*1000) % 65530 -- SIC!
if not os.getComputerLabel() then os.setComputerLabel("KT"..uniqueID) end

-- Required to open channels before working with modem
local function openModem()
  if modemOpened then return true end

  for n,sSide in ipairs( rs.getSides() ) do
    if rednet.isOpen( sSide ) then
      modemOpened = true
      return true
    end
  end
  for n,sSide in ipairs( rs.getSides() ) do
    if peripheral.getType( sSide )=='modem' then
      peripheral.call( sSide, "open", uniqueID )
      peripheral.call( sSide, "open", CHANNEL_BROADCAST )
      modem = peripheral.wrap(sSide)
      modemOpened = true
      return true
    end
  end
  return false
end
openModem()

-- Searching value in table by keys
local function tblContainsVal(table, key, val)
  for k, v in pairs(table) do
    if v[key] == val then
      return k
    end
  end
  return nil
end

-- Receive message with timeout
local function receive(nTimeout)
  -- Start the timer
	local timer = nil
	local sFilter = nil
	if nTimeout then
		timer = os.startTimer( nTimeout )
		sFilter = nil
	else
		sFilter = "modem_message"
	end

	-- Wait for events
	while true do
		local sEvent, p1, p2, p3, p4, p5 = os.pullEvent( sFilter )
		if sEvent == "modem_message" then
	    -- Return the first matching modem_message
	    -- senderId, msg, channel
    	return p3, p4, p5
		elseif sEvent == "timer" then
      -- Return nil if we timeout
      if p1 == timer then
        return nil
      end
		end
	end
end


------------------------------
-- Functions called from turtles
------------------------------

-- Looking for broadcast from master. If so, sending answer with distance
function swarm.searchOwner()

  local senderId, msg, distance
  while msg~=MASTERMESSAGE do
    _,_,_,senderId, msg,distance = os.pullEvent("modem_message")
    if msg==MASTERMESSAGE then
      -- We gained first message from master.
      -- Send back a distance
      masterId = senderId
      modem.transmit(senderId, uniqueID, distance)
    end
  end

  return distance
end


-- Waiting for order message till find
function swarm.waitOrders()

  local senderId, message, channel
  while senderId ~= masterId and channel ~= CHANNEL_BROADCAST do
    _,_,channel,senderId, message = os.pullEvent("modem_message")
  end

  -- Send confirm
  swarm.transmitToMaster({name=CONFIRMMESSAGE})

  return table.fromString(message)
end


-- Call broadcast and waiting for responces, collecting them to array
function swarm.findSlaves(waitingResponceTime)
  if not modemOpened then return 0 end

  -- Broadcast
  modem.transmit(CHANNEL_BROADCAST, uniqueID, MASTERMESSAGE)

  local received={}
  local senderId, message = receive(waitingResponceTime); if IDE then senderId, message = "slave1", 1 end
  while senderId do
    if(type(tonumber(message)) == 'number') then
      table.insert(received, {id=senderId, dist=tonumber(message)})
    end
    senderId, message = receive(waitingResponceTime)
  end
  table.sort(received,function(s1,s2) return s1.dist < s2.dist end)

  slaves = {}
  local k=1
  for _,v in pairs(received) do
    if(v.dist == k) then
      k = k+1
      table.insert(slaves, v)
    else
      break
    end
  end

  return k-1
end

-- Call broadcast and waiting for responces, and add only nearest
function swarm.addSlave()
  if not modemOpened then return nil end

  while true do

    -- Broadcast
    modem.transmit(CHANNEL_BROADCAST, uniqueID, MASTERMESSAGE)

    local senderId, message = receive(0.5)
    while senderId do
      local n = tonumber(message)
      if type(n) == 'number' and n == 1 then
        table.insert(slaves, 1, {id=senderId, dist=nil})
        return true
      end
      senderId, message = receive(0.5)
    end
  end
  return nil
end


-- Send message from owner to slave
function swarm.transmitTask(turtleNumber, taskObj, needConfirm)
  local slaveId = slaves[turtleNumber].id
  while true do
    modem.transmit(slaveId, uniqueID, table.toString(taskObj))

    if needConfirm then
      local senderId, msg = receive(0.5)
      while senderId do
        local receivedObj = table.fromString(msg)
        if senderId == slaveId and receivedObj and receivedObj.name == CONFIRMMESSAGE then
          return true
        end
        senderId, msg = receive(0.5)
      end
    else
      return true
    end
  end
end

-- If we have something
function swarm.transmitToMaster(obj)
  modem.transmit(masterId, uniqueID, table.toString(obj))
end


-- Receive troubles
function swarm.receiveFromSlave(waitingResponceTime)
  local senderId, msg, channel = receive(waitingResponceTime)

  if not senderId then return end

  local n = tblContainsVal(slaves, 'id', senderId)
  if n~= nil and channel ~= CHANNEL_BROADCAST then
    local receivedObj = table.fromString(msg)
    if not receivedObj then return end
    receivedObj.slaveId = n
    return receivedObj
  end
end


-- Waiting broadcast that means i
function swarm.waitGetout()
  local senderId, msg, distance
  while true do
    _,_,_,senderId, msg,distance = os.pullEvent("modem_message")
    if msg==GETOUTMESSAGE and distance == 1 then
      return true
    end
  end
end

-- Waiting broadcast that means i
function swarm.sendGetout()
  -- Broadcast
  modem.transmit(CHANNEL_BROADCAST, uniqueID, GETOUTMESSAGE)
end





-- 40_AStar.lua
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

-- Method that switfly finds the best path from p_start to end. Doesn't reverse outcome
-- The p_end breadcrump where each .next is a step back
local function FindPathReversed(world, p_start, p_end)

  -- Destination point is bloked
  if world(p_start.x, p_start.y, p_start.z) then return end

  local openList = {}
  local brWorld  = arr3d()


  local current= BreadCrumb.new(p_start.x,p_start.y,p_start.z)
  current.cost = 0

  local finish = BreadCrumb.new(p_end.x,p_end.y,p_end.z)
  brWorld:set(current.pos.x,current.pos.y,current.pos.z,current)
  insert(openList,current)

  --while openList.count > 0 do
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
            while pos > 1 and openList[pos].cost < node.cost do
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

-- Method that switfly finds the best path from p_start to end.
-- The starting breadcrumb traversable via .next to the end or nil if there is no path
function AStarFindPath(world, p_start, p_end)
    -- note we just flip p_start and end here so you don't have to.
    return FindPathReversed(world, p_end, p_start)
end

-- ********************************************************************************** --
-- **                              Usage                                           ** --
-- ********************************************************************************** --


--[[
-- Create new world as 3d array
local world = arr3d()

-- Block a cell, make it impassable. Indexes from [0]
-- Indexes is [x][y][z]
world:set(1,4,3,true)


local p_start = {x=1,y=2,z=3} -- Start point.
local p_end   = {x=1,y=6,z=3} -- End point

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
]]--






-- 50_TableToString.lua
-- ********************************************************************************** --
-- **   Serialize table to string                                                  ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- declare local variables
--// exportstring( string )
--// returns a "Lua" portable version of the string
local function exportstring( s )
  return string.format("%q", s)
end

local insert  = table.insert
local tostring= tostring
local ipairs  = ipairs
local pairs   = pairs
local type    = type

--// The Save Function
function table.toString(tbl)
  if not tbl then return "" end

  local charS,charE = "   ","\n"
  local s_tbl = {}

  -- initiate variables for save procedure
  local tables,lookup = { tbl },{ [tbl] = 1 }
  insert(s_tbl, "return {"..charE )

  for idx,t in ipairs( tables ) do
    insert(s_tbl, "-- Table: {"..idx.."}"..charE )
    insert(s_tbl, "{"..charE )
    local thandled = {}

    for i,v in ipairs( t ) do
      thandled[i] = true
      local stype = type( v )
      -- only handle value
      if stype == "table" then
        if not lookup[v] then
          insert( tables, v )
          lookup[v] = #tables
        end
        insert(s_tbl, charS.."{"..lookup[v].."},"..charE )
      elseif stype == "string" then
        insert(s_tbl,  charS..exportstring( v )..","..charE )
      elseif stype == "number" or stype == "boolean" then
        insert(s_tbl,  charS..tostring( v )..","..charE )
      end
    end

    for i,v in pairs( t ) do
      -- escape handled values
      if (not thandled[i]) then

        local str = ""
        local stype = type( i )
        -- handle index
        if stype == "table" then
          if not lookup[i] then
            insert( tables,i )
            lookup[i] = #tables
          end
          str = charS.."[{"..lookup[i].."}]="
        elseif stype == "string" then
          str = charS.."["..exportstring( i ).."]="
        elseif stype == "number" or stype == "boolean" then
          str = charS.."["..tostring( i ).."]="
        end

        if str ~= "" then
          stype = type( v )
          -- handle value
          if stype == "table" then
            if not lookup[v] then
              insert( tables,v )
              lookup[v] = #tables
            end
            insert(s_tbl, str.."{"..lookup[v].."},"..charE )
          elseif stype == "string" then
            insert(s_tbl, str..exportstring( v )..","..charE )
          elseif stype == "number" or stype == "boolean" then
            insert(s_tbl, str..tostring( v )..","..charE )
          end
        end
      end
    end
    insert(s_tbl, "},"..charE )
  end
  insert(s_tbl, "}" )

  return table.concat(s_tbl)
end

--// The Load Function
function table.fromString(s)
  if not s then return end
  local ftables = loadstring(s)
  if not ftables then return end
  local tables = ftables()
  for idx = 1,#tables do
    local tolinki = {}
    for i,v in pairs( tables[idx] ) do
      if type( v ) == "table" then
        tables[idx][i] = tables[v[1]]
      end
      if type( i ) == "table" and tables[i[1]] then
        insert( tolinki,{ i,tables[i[1]] } )
      end
    end
    -- link indices
    for _,v in ipairs( tolinki ) do
      tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
    end
  end
  return tables[1]
end






-- 60_Thread.lua
-- ********************************************************************************** --
-- **   Thread                                                                     ** --
-- **   by ZeroGalaxy                                                              ** --
-- **   ----------------------------------------------------                       ** --
-- **                                                                              ** --
-- **   Easy acces to parralel process in ComputerCraft                            ** --
-- **   http://computercraft.ru/topic/393                                          ** --
-- **                                                                              ** --
-- ********************************************************************************** --

thread = {}
thread.__index = thread

local mainThread=coroutine.running()
local filter={}

local function SingleThread( _sFilter )
  return coroutine.yield( _sFilter )
end

local function MultiThread( _sFilter )
  if coroutine.running()==mainThread then
    local event,co
    repeat
      event={coroutine.yield()}
      co=next(filter)
      if not co then os.pullEventRaw=SingleThread end
      while co do
        if coroutine.status( co ) == "dead" then
          filter[co],co=nil,next(filter,co)
        else
          if filter[co] == '' or filter[co] == event[1] or event[1] == "terminate" then
        local ok, param = coroutine.resume( co, unpack(event) )
        if not ok then filter={} error( param )
        else filter[co] = param or '' end
          end
          co=next(filter,co)
        end
      end
    until _sFilter == nil or _sFilter == event[1] or event[1] == "terminate"
    return unpack(event)
  else
  return coroutine.yield( _sFilter )
  end
end

function thread.create(f,...)
  os.pullEventRaw=MultiThread
  local co=coroutine.create(f)
  filter[co]=''
  local ok, param = coroutine.resume( co, ... )
  if not ok then filter={} error( param )
  else filter[co] = param or '' end
  return co
end

function thread.kill(co)
  filter[co]=nil
end

function thread.killAll()
  filter={}
  os.pullEventRaw=SingleThread
end





-- 70_VolumeLoaders.lua
-- ********************************************************************************** --
-- **   Loader of .vox files from MagivaVoxels editor and .nfa files from NPaintPRO** --
-- **   https://voxel.codeplex.com                                                 ** --
-- **                                                                              ** --
-- ********************************************************************************** --

volumeLoader = {}
volumeLoader.__index = volumeLoader


--===========================================================
-- Read string from binary file with
--===========================================================
local function readBString(file, len)
  local s = ''
  for i=1,len do
    s = s .. string.char(file.read())
  end
  return s
end

--===========================================================
-- Read 4 bites and convert them to integer
--===========================================================
local function readBInt(file)
  local t = {}
  for i=1,4 do table.insert(t, file.read()) end
  local n=0
  for k=1,#t do
      n=n+t[k]*2^((k-1)*8)
  end
  return n
end

--===========================================================
-- Locad voxel files from program MagcaVoxels
--===========================================================
function volumeLoader.load_vox(path)
  local bFile = fs.open(path, "rb")

  local magic = readBString(bFile, 4)
  assert(magic=="VOX ")

  local version = readBString(bFile, 4)

  local mainChunkID = readBString(bFile, 4)
  assert(mainChunkID=="MAIN")

  local mainChunkSize   = readBInt(bFile)
  local mainchildChunks = readBInt(bFile)
  readBString(bFile, mainChunkSize)

  local sizeID = readBString(bFile, 4)
  assert(sizeID=="SIZE")
  readBString(bFile, 8) -- Dont know what this two numbers means.

  local sizeX = readBInt(bFile)
  local sizeY = readBInt(bFile)
  local sizeZ = readBInt(bFile)

  local voxelID = readBString(bFile, 4)
  assert(voxelID=="XYZI")
  readBString(bFile, 8) -- Dont know what this two numbers means.
  local numVoxels= readBInt(bFile)

  local vol = {}
  for j=1, numVoxels do
    local x,y,z,i = bFile.read(),bFile.read(),bFile.read(),bFile.read()

    vol[z+1]           = vol[z+1]      or {}
    vol[z+1][y+1]      = vol[z+1][y+1] or {}
    vol[z+1][y+1][x+1] = i
  end
  bFile.close()

  return vol, sizeX, sizeY, sizeZ
end



--===========================================================
-- Load files from NPaintPro
--===========================================================
function volumeLoader.load_nfa(path)
  if fs.exists(path) == false then
    return nil
  end

  local vol = { }
  vol[1] = { }

  local file = io.open(path, "r" )
  local sLine = file:read()
  local z = 1
  local y = 1
  while sLine do
    if sLine == "~" then
      z = z + 1
      vol[z] = {}
      y = 1
    else
      vol[z][y] = vol[z][y] or {}
      local x=1
      for i=1,#sLine do
        vol[z][y][x] = tonumber(string.sub(sLine,i,i), 16)
        x=x+1
      end
      y = y+1
    end
    sLine = file:read()
  end
  file:close()

  return vol
end





-- 99_main.lua
main()
