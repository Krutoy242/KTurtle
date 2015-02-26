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
local masterId
local slaves
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
		local sEvent, p1, p2, p3, p4 = os.pullEvent( sFilter )
		if sEvent == "modem_message" then
		    -- Return the first matching modem_message
			local senderId, msg = p3, p4
    	return senderId, msg
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
  openModem()
  
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

  local senderId, message
  while senderId ~= masterId do
    _,_,_,senderId, message = os.pullEvent("modem_message")
  end
  
  return table.fromString(message)
end


-- Call broadcast and waiting for responces, collecting them to array
function swarm.findSlaves(waitingResponceTime)
  if not modemOpened then return 0 end

  -- Broadcast
  modem.transmit(CHANNEL_BROADCAST, uniqueID, MASTERMESSAGE)
  
  local received={}
  local senderId, message = receive(waitingResponceTime)
  if IDE then senderId, message = "slave1", 1 end
  while senderId do
    if(type(tonumber(message)) == 'number') then
      table.insert(received, {id=senderId, dist=tonumber(message)})
      senderId, message = receive(waitingResponceTime)
    end
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


-- Send message from owner to slave
function swarm.transmitTask(turtleNumber, taskObj)
  modem.transmit(slaves[turtleNumber].id, uniqueID, table.toString(taskObj))
end

-- If we have troubles, send them
function swarm.transmitError(errorString)
  modem.transmit(masterId, uniqueID, errorString)
end

-- Receive troubles
function swarm.receiveError(waitingResponceTime)

  local errorsStack
  local senderId, message = receive(waitingResponceTime)
  while senderId do
    local n = tblContainsVal(slaves, 'id', senderId)
    if n ~= nil then
      errorsStack = errorsStack or {}
      errorsStack[n] = message
    end
    senderId, message = receive(waitingResponceTime)
  end
    
  return errorsStack
end
