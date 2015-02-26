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
