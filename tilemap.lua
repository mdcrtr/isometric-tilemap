local resource = require "resource"


local MAP_SZ = 32
local HMAP_SZ = MAP_SZ + 1
local TILE_W = 32
local TILE_H = 16
local TILE_HW = TILE_W / 2
local TILE_HH = TILE_H / 2

local tiles = {} ---@type Tile[]
local heightMap = {} ---@type number[]

---@type Vec[]
local adjacentPositions = {
  { x = -1, y = -1 },
  { x = 0,  y = -1 },
  { x = 1,  y = -1 },
  { x = -1, y = 0 },
  { x = 1,  y = 0 },
  { x = -1, y = 1 },
  { x = 0,  y = 1 },
  { x = 1,  y = 1 },
}

---@param x number
---@param y number
---@return number
local function toTileMapIndex(x, y)
  return y * MAP_SZ + x + 1
end

---@param x number
---@param y number
---@return number
local function toHeightMapIndex(x, y)
  return y * HMAP_SZ + x + 1
end

---@param texName string
---@return Tile
local function newTile(texName)
  return {
    texInfo = resource.atlas[texName],
    hy = 0
  }
end

local M = {}

---@param x number
---@param y number
---@return boolean
function M.validTileCoord(x, y)
  return x >= 0 and y >= 0 and x < MAP_SZ and y < MAP_SZ
end

---@param x number
---@param y number
---@return boolean
function M.validHeightMapCoord(x, y)
  return x >= 0 and y >= 0 and x < HMAP_SZ and y < HMAP_SZ
end

---@param x number
---@param y number
---@return number
function M.getHeight(x, y)
  if not M.validHeightMapCoord(x, y) then return 0 end
  return heightMap[toHeightMapIndex(x, y)]
end

---@param x number
---@param y number
---@return number
function M.getMinHeight(x, y)
  return math.min(
    M.getHeight(x, y), M.getHeight(x + 1, y),
    M.getHeight(x + 1, y + 1), M.getHeight(x, y + 1)
  )
end

---@param x number
---@param y number
---@return number, number
function M.gridToWorld(x, y)
  local px = (x - y) * TILE_HW
  local py = (x + y) * TILE_HH
  return px, py
end

---@param x number
---@param y number
---@return number, number
function M.worldToGridFloat(x, y)
  local gx = (x / TILE_HW + y / TILE_HH) / 2
  local gy = (y / TILE_HH - x / TILE_HW) / 2
  return gx, gy
end

---@param x number
---@param y number
---@return number, number
function M.worldToGrid(x, y)
  local gx, gy = M.worldToGridFloat(x, y)
  return math.floor(gx), math.floor(gy)
end

---@param x number
---@param y number
---@param fixedHeight number?
---@return number, number
function M.snapToGridPoint(x, y, fixedHeight)
  local fx, fy = M.worldToGridFloat(x, y)

  if fixedHeight then
    local offset = fixedHeight * 0.5
    local gridX = math.floor(fx + 0.5 + offset)
    local gridY = math.floor(fy + 0.5 + offset)
    return gridX, gridY
  end

  local startX = math.floor(fx)
  local startY = math.floor(fy)
  local closestX = startX
  local closestY = startY
  local closestDist = 999999

  local function checkPoint(gx, gy)
    local h = M.getHeight(gx, gy)
    local px = gx - h * 0.5
    local py = gy - h * 0.5
    local dist = (fx - px) ^ 2 + (fy - py) ^ 2
    if dist < closestDist then
      closestX = gx
      closestY = gy
      closestDist = dist
    end
  end

  for i = 0, 8 do
    local gx = startX + i
    local gy = startY + i
    checkPoint(gx, gy)
    checkPoint(gx + 1, gy)
    checkPoint(gx, gy + 1)
  end

  return closestX, closestY
end

---@param x number
---@param y number
---@return Tile | nil
function M.getTile(x, y)
  if not M.validTileCoord(x, y) then return nil end
  return tiles[toTileMapIndex(x, y)]
end

---@param x number
---@param y number
---@return number
local function getHeightPattern(x, y)
  local heights = {
    M.getHeight(x, y),
    M.getHeight(x + 1, y),
    M.getHeight(x + 1, y + 1),
    M.getHeight(x, y + 1),
  }
  local minHeight = math.min(heights[1], heights[2], heights[3], heights[4])
  for i, h in ipairs(heights) do
    if h == minHeight then
      heights[i] = 0
    else
      heights[i] = 1
    end
  end
  local pattern = heights[1]
  pattern = pattern + heights[2] * 2
  pattern = pattern + heights[3] * 4
  pattern = pattern + heights[4] * 8
  return pattern + 1
end

---@param x number
---@param y number
local function updateTileQuad(x, y)
  if not M.validTileCoord(x, y) then return end
  local pattern = getHeightPattern(x, y)
  local tile = M.getTile(x, y)
  local h = M.getMinHeight(x, y)
  tile.hy = h * 8
  tile.texInfo = resource.patternToTexInfo(pattern)
end

---@param x number
---@param y number
local function smoothTerrain(x, y)
  local h1 = M.getHeight(x, y)
  for _, v in ipairs(adjacentPositions) do
    local nx = x + v.x
    local ny = y + v.y
    if M.validHeightMapCoord(nx, ny) then
      local h2 = M.getHeight(nx, ny)
      if h2 - h1 > 1 then
        M.lowerTerrain(nx, ny)
      elseif h1 - h2 > 1 then
        M.raiseTerrain(nx, ny)
      end
    end
  end
end

function M.init()
  tiles = {}
  heightMap = {}
  for _ = 1, MAP_SZ * MAP_SZ do
    table.insert(tiles, newTile("grass"))
  end
  for _ = 1, HMAP_SZ * HMAP_SZ do
    table.insert(heightMap, 0)
  end
end

function M.draw()
  for y = 0, MAP_SZ - 1 do
    for x = 0, MAP_SZ - 1 do
      local px, py = M.gridToWorld(x, y)
      px = px - TILE_HW
      local tile = tiles[toTileMapIndex(x, y)]
      local texInfo = tile.texInfo
      py = py + texInfo.oy - tile.hy
      love.graphics.draw(resource.texture, texInfo.quad, px, py)
    end
  end
end

---@param x number
---@param y number
---@param h number
function M.setTerrainHeight(x, y, h)
  if not M.validHeightMapCoord(x, y) then return end
  if h < 0 or h > 12 then return end
  local i = toHeightMapIndex(x, y)
  heightMap[i] = h
  smoothTerrain(x, y)
  updateTileQuad(x, y)
  updateTileQuad(x - 1, y)
  updateTileQuad(x - 1, y - 1)
  updateTileQuad(x, y - 1)
end

---@param x number
---@param y number
function M.raiseTerrain(x, y)
  local h = M.getHeight(x, y)
  M.setTerrainHeight(x, y, h + 1)
end

---@param x number
---@param y number
function M.lowerTerrain(x, y)
  local h = M.getHeight(x, y)
  M.setTerrainHeight(x, y, h - 1)
end

return M
