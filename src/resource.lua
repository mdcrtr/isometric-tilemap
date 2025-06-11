---Creates a TexInfo object containing texture coordinates for a tile.
---@param name string
---@param x number
---@param y number
---@param w number
---@param h number
---@param oy number?
---@return TexInfo
local function newTexInfo(name, x, y, w, h, oy)
  return {
    name = name,
    quad = love.graphics.newQuad(x, y, w, h, 256, 256),
    oy = oy or (16 - h)
  }
end

---Converts 4 bit tile height pattern to TexInfo
---@type string[]
local patternToAltasName = {
  "grass",     -- 0000
  "slopeSE",   -- 0001
  "slopeSW",   -- 0010
  "slopeS",    -- 0011
  "slopeNW",   -- 0100
  "slopeSE",   -- 0101
  "slopeW",    -- 0110
  "dipSW",     -- 0111
  "slopeNE",   -- 1000
  "slopeE",    -- 1001
  "slopeNESW", -- 1010
  "dipSE",     -- 1011
  "slopeN",    -- 1100
  "dipNE",     -- 1101
  "dipNW",     -- 1110
  "grass",     -- 1111
}

local M = {}

---Atlas of tile texture coordinates.
---@type {[string]: TexInfo}
M.atlas = {
  empty = newTexInfo("empty", 1, 1, 0, 0),
  grass = newTexInfo("grass", 32, 0, 32, 16),
  water = newTexInfo("water", 96, 0, 32, 16),
  slopeSW = newTexInfo("slopeSW", 0, 16, 32, 32),
  slopeS = newTexInfo("slopeS", 32, 16, 32, 32),
  slopeSE = newTexInfo("slopeSE", 64, 16, 32, 32),
  slopeE = newTexInfo("slopeE", 96, 16, 32, 32),
  slopeNE = newTexInfo("slopeNE", 0, 48, 32, 32),
  slopeN = newTexInfo("slopeN", 32, 48, 32, 32),
  slopeNW = newTexInfo("slopeNW", 64, 48, 32, 32),
  slopeW = newTexInfo("slopeW", 96, 48, 32, 32),
  slopeNESW = newTexInfo("slopeNESW", 128, 48, 32, 32),
  dipNW = newTexInfo("dipNW", 0, 80, 32, 16, -8),
  dipSW = newTexInfo("dipSW", 32, 80, 32, 32, -8),
  dipSE = newTexInfo("dipSE", 64, 80, 32, 32, -8),
  dipNE = newTexInfo("dipNE", 96, 80, 32, 32, -8),
  tree = newTexInfo("tree", 128, 0, 32, 32, -16),
  house = newTexInfo("house", 160, 0, 32, 32, -16),
  creature = newTexInfo("creature", 192, 0, 8, 8),
}

---Loads resources.
function M.load()
  M.texture = love.graphics.newImage("assets/iso-tiles2.png")
  M.texture:setFilter("nearest", "nearest")
end

---Converts a 4 bit tile height pattern to tile texture coordinates.
---The 4 bit pattern represents the relative height of the NE,NW,SW,SE tile vertices.
---@param pattern number 4 bit pattern
---@return TexInfo - Tile texture coordinates
function M.patternToTexInfo(pattern)
  return M.atlas[patternToAltasName[pattern]]
end

return M
