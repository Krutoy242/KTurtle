

-- Redefine global function for faster acces
local floor = math.floor
local ceil  = math.ceil
local insert= table.insert 
local min   = math.min
local max   = math.max


--===========================================================
-- Inline help functions
--===========================================================
local function clearScreen()     term.clear(); term.setCursorPos(1,1) end
local function tblLen(tbl)       local n=0;       for _,_  in pairs(tbl) do n = n + 1 end return n end
local function makeSet(list)     local set = {};  for _, v in pairs(list) do set[v] = true end return set end
local function pressAnyKey()     local event, param1 = os.pullEvent ("key") end
local function getChar(str, pos) return string.sub(str, pos, pos) end


function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


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
  end,
  raw = function(t)
    local raw = shallowcopy(t)
    raw.set, raw.setVolume, raw.raw = nil,nil,nil
    return raw
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