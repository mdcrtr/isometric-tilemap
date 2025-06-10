local C = require "constants"
local resource = require "resource"

---List of tiles in the map.
local tiles = {} ---@type Tile[]

---List of height map vertices in the map.
---The height map is 1 element larger than the tilemap in each dimension,
---as the vertices are at the corners of the tile.
local heightMap = {} ---@type number[]

---@type Tile
local dummyTile = {
  texInfo = resource.atlas["empty"],
  hy = 0,
  structure = resource.atlas["empty"]
}

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
  return y * C.MAP_SZ + x + 1
end

---@param x number
---@param y number
---@return number
local function toHeightMapIndex(x, y)
  return y * C.HMAP_SZ + x + 1
end

---@param texName string
---@param height number
---@return Tile
local function newTile(texName, height)
  return {
    texInfo = resource.atlas[texName],
    hy = height * C.TILE_HH,
    structure = resource.atlas["empty"]
  }
end

local M = {}

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
  if h == 0 and M.getMaxHeight(x, y) == 0 then
    tile.texInfo = resource.atlas["water"]
  else
    tile.texInfo = resource.patternToTexInfo(pattern)
  end
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

---Checks if the tile map coordinates are valid.
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
---@return boolean - Valid
function M.validTileCoord(x, y)
  return x >= 0 and y >= 0 and x < C.MAP_SZ and y < C.MAP_SZ
end

---Checks if the height map coordinates are valid.
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
---@return boolean - Valid
function M.validHeightMapCoord(x, y)
  return x >= 0 and y >= 0 and x < C.HMAP_SZ and y < C.HMAP_SZ
end

---Gets the height of a height map vertex.
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
---@return number - Grid height
function M.getHeight(x, y)
  if not M.validHeightMapCoord(x, y) then return 0 end
  return heightMap[toHeightMapIndex(x, y)]
end

---Gets the minimum height of a tile.
---Each tile has 4 height map vertices.
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
---@return number - Grid height
function M.getMinHeight(x, y)
  return math.min(
    M.getHeight(x, y), M.getHeight(x + 1, y),
    M.getHeight(x + 1, y + 1), M.getHeight(x, y + 1)
  )
end

---Gets the maximum height of a tile.
---Each tile has 4 height map vertices.
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
---@return number - Grid height
function M.getMaxHeight(x, y)
  return math.max(
    M.getHeight(x, y), M.getHeight(x + 1, y),
    M.getHeight(x + 1, y + 1), M.getHeight(x, y + 1)
  )
end

---Converts Grid coordinates into World position.
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
---@return number, number - World X/Y position
function M.gridToWorld(x, y)
  local px = (x - y) * C.TILE_HW
  local py = (x + y) * C.TILE_HH
  return px, py
end

---Converts World position into Grid coordinates (fractional).
---@param x number World X position
---@param y number World Y position
---@return number, number - Grid X/Y coordinates
function M.worldToGridFloat(x, y)
  local gx = (x / C.TILE_HW + y / C.TILE_HH) / 2
  local gy = (y / C.TILE_HH - x / C.TILE_HW) / 2
  return gx, gy
end

---Converts World position into Grid coordinates (floored to tile origin).
---@param x number World X position
---@param y number World Y position
---@return number, number - Grid X/Y coordinates
function M.worldToGrid(x, y)
  local gx, gy = M.worldToGridFloat(x, y)
  return math.floor(gx), math.floor(gy)
end

---Snaps world position to the nearest grid point, taking height into account.
---@param x number World X position
---@param y number World Y position
---@param fixedHeight number? Snap to a specific height, or snap to terrain height
---@return number, number - Snapped Grid X, Y coordinate
function M.snapToGridPoint(x, y, fixedHeight)
  local fx, fy = M.worldToGridFloat(x, y)

  -- Snap to a fixed height
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

  -- Lift the grid position to its terrain height and check if it is
  -- closer to fx/fy than the previously checked point.
  local function checkPoint(gx, gy)
    local h = M.getHeight(gx, gy)
    -- Each step in height obscures 50% of the tile behind it.
    local px = gx - h * 0.5
    local py = gy - h * 0.5
    local dist = (fx - px) ^ 2 + (fy - py) ^ 2
    if dist < closestDist then
      closestX = gx
      closestY = gy
      closestDist = dist
    end
  end

  -- Do a linear search to check if there are any higher grid points that
  -- are closer to the initial snapped position.
  for i = 0, 8 do
    local gx = startX + i
    local gy = startY + i
    checkPoint(gx, gy)
    checkPoint(gx + 1, gy)
    checkPoint(gx, gy + 1)
  end

  return closestX, closestY
end

---Gets a tile
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
---@return Tile
function M.getTile(x, y)
  if not M.validTileCoord(x, y) then return dummyTile end
  return tiles[toTileMapIndex(x, y)]
end

---Initialises all tiles and sets the height to default
function M.init()
  tiles = {}
  heightMap = {}
  for _ = 1, C.MAP_SZ * C.MAP_SZ do
    table.insert(tiles, newTile("grass", 1))
  end
  for _ = 1, C.HMAP_SZ * C.HMAP_SZ do
    table.insert(heightMap, 1)
  end
end

---Draws the tile map
function M.draw()
  local texture = resource.texture
  for y = 0, C.MAP_SZ - 1 do
    for x = 0, C.MAP_SZ - 1 do
      local px, py = M.gridToWorld(x, y)
      px = px - C.TILE_HW
      local tile = tiles[toTileMapIndex(x, y)]
      local texInfo = tile.texInfo
      py = py + texInfo.oy - tile.hy
      love.graphics.draw(texture, texInfo.quad, px, py)
      local structureInfo = tile.structure
      if structureInfo.name ~= "empty" then
        py = py - texInfo.oy + structureInfo.oy
        love.graphics.draw(texture, structureInfo.quad, px, py)
      end
    end
  end
end

---Sets the height of a height map vertex
---Adjacent vertices are pulled up/down to prevent cliffs
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
---@param h number The height to set
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

---Raises the height of a height map vertex
---Adjacent vertices are pulled up to prevent cliffs
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
function M.raiseTerrain(x, y)
  local h = M.getHeight(x, y)
  M.setTerrainHeight(x, y, h + 1)
end

---Lowers the height of a height map vertex.
---Adjacent vertices are pulled down to prevent cliffs.
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
function M.lowerTerrain(x, y)
  local h = M.getHeight(x, y)
  M.setTerrainHeight(x, y, h - 1)
end

---Adds a structure to the tilemap
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
---@param name string TexInfo name
function M.addStructure(x, y, name)
  if not M.validTileCoord(x, y) then return end
  M.getTile(x, y).structure = resource.atlas[name]
end

---Removes a structure from the tilemap
---@param x number Grid X coordinate
---@param y number Grid Y coordinate
function M.removeStucture(x, y)
  if not M.validTileCoord(x, y) then return end
  M.getTile(x, y).structure = resource.atlas["empty"]
end

return M
