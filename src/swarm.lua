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
local masterId
local slaves = {}
local modem
local uniqueID = math.random * 65530 -- SIC!
--local uniqueID = math.floor(os.time()*1000) % 65530 -- SIC!
if not os.getComputerLabel() then os.setComputerLabel("KT"..uniqueID) end
local hashes = {} -- Set of all hashes that had been received

-- No-Modem mode
local touch = {
["getout"] = 14,
["killMe"] = 13,
["nomodem"]= 12,
["master"] = 11
}

local sidesList = {"top", "bottom", "left", "right", "front", "back"}



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
swarm.nomodem = not openModem() -- With this flag we getting fill volume from floppy

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
	local timer, sFilter
	if nTimeout then
		timer = os.startTimer( nTimeout )
	else
		sFilter = "modem_message"
	end

	-- Wait for events
	while true do
		local sEvent, p1, p2, p3, p4, p5 = os.pullEvent( sFilter )
		if sEvent == "modem_message" then
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
    local sEvent
    sEvent,_,_,senderId, msg,distance = os.pullEvent()

    if sEvent == "redstone" then
      -- This is redstone message from owner.
      -- Even if we have no modem, we still can communicate with it
      for i=1, #sidesList do
        if rs.getAnalogInput(sidesList[i]) == touch["master"] then
          swarm.nomodem = true
          return 1
        end
      end
    elseif sEvent=="modem_message" and msg==MASTERMESSAGE then    
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
  while true do
    _,_,channel,senderId, message = os.pullEvent("modem_message")
    
    if senderId == masterId or channel == CHANNEL_BROADCAST then
      local obj = table.fromString(message)
      
      if not (obj and obj.messageHash and hashes[obj.messageHash]) then
        
        -- Send confirm
        swarm.transmitToMaster(message)
        
        -- Add this hash to hash table
        if obj and obj.messageHash then hashes[obj.messageHash] = true end
        
        return obj
      end
    end
  end
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
  local messageHash = math.floor(math.random()*(2^20))
  taskObj.messageHash = messageHash
  local slaveId
  local received = {} -- Set of all confirms
  local taskString = table.toString(taskObj)
  
  
  while true do
    -- Transmit message to all turtles or to one
    if turtleNumber == nil then
      for k,v in pairs(slaves) do
        slaveId = v.id
        modem.transmit(slaveId, uniqueID, taskString)
      end
    else
      slaveId = slaves[turtleNumber].id
      modem.transmit(slaveId, uniqueID, taskString)
    end
    
    -- Instant leave function if not need to wait responce
    if not needConfirm then return true end
    
    -- Receive loop
    local senderId, msg, channel = receive(0.5)
    while senderId do
      local receivedObj = table.fromString(msg)
      
      if turtleNumber == nil then
        -- Check if we have this turtle in our list
        -- And if so, add to receive
        local n = tblContainsVal(slaves, 'id', senderId)
        if n~= nil and channel ~= CHANNEL_BROADCAST then
          received[senderId] = true
        end
        
        -- If we received confirms from all turtles, return
        if tblLen(received) == tblLen(slaves) then return true end
      else
        if senderId == slaveId and receivedObj and receivedObj.messageHash == messageHash then
          return true
        end
      end
      
      senderId, msg, channel = receive(0.5)
    end
  end
end

-- If we have something
function swarm.transmitToMaster(obj)
  if type(obj) == 'table' then obj = table.toString(obj) end
  modem.transmit(masterId, uniqueID, obj)
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

-- Touch by string key
function swarm.touch(key, direction)
  Turtle.touch(touch[key], direction)
end

-- Feel touch key
function swarm.sense(direction)
  local strength = Turtle.sense(direction)
  for k,v in pairs(touch) do
    if v == strength then return k end
  end
end