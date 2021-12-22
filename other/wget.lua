
local function printUsage()
    print( "Usages:" )
    print( "wget <URL> <filename>" )
end
 
local tArgs = { ... }
if #tArgs < 2 then
    printUsage()
    return
end
 
if not http then
    printError( "wget requires http API" )
    printError( "Set enableAPI_http to true in ComputerCraft.cfg" )
    return
end
 
local function get(url)
    write( "Connecting... " )
    local response = http.get(url)
        
    if response then
        print( "Success." )
        
        local sResponse = response.readAll()
        response.close()
        return sResponse
    else
        printError( "Failed." )
    end
end
 
local sCommand = tArgs[1]
if type(tArgs[1]) == "string" and type(tArgs[2]) == "string" then
    -- Determine file to download
    local sUrl  = tArgs[1]
    local sFile = tArgs[2]
    local sPath = shell.resolve( sFile )
    if fs.exists( sPath ) then
        print( "File already exists" )
        return
    end
    
    -- GET the contents from pastebin
    local res = get(sUrl)
    if res then        
        local file = fs.open( sPath, "w" )
        file.write( res )
        file.close()
        
        print( "Downloaded as "..sFile )
    end 
else
    printUsage()
    return
end