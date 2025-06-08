local resource = require "resource"

local M = {}

M.MAP_SZ = 32
M.HMAP_SZ = M.MAP_SZ + 1
M.TILE_W = 32
M.TILE_H = 16
M.TILE_HW = M.TILE_W / 2
M.TILE_HH = M.TILE_H / 2
M.tiles = {} ---@type Tile[]
M.heightMap = {} ---@type number[]

---@type Vec[]
M.adjacentPositions = {
  { x = -1, y = -1 },
  { x = 0,  y = -1 },
  { x = 1,  y = -1 },
  { x = -1, y = 0 },
  { x = 1,  y = 0 },
  { x = -1, y = 1 },
  { x = 0,  y = 1 },
  { x = 1,  y = 1 },
}

---@param texName string
---@return Tile
function M.newTile(texName)
  return {
    texInfo = resource.atlas[texName],
    hy = 0
  }
end

---@param x number
---@param y number
---@return number
function M.toTileMapIndex(x, y)
  return y * M.MAP_SZ + x + 1
end

---@param x number
---@param y number
---@return number
function M.toHeightMapIndex(x, y)
  return y * M.HMAP_SZ + x + 1
end

---@param x number
---@param y number
---@return boolean
function M.validTileCoord(x, y)
  return x >= 0 and y >= 0 and x < M.MAP_SZ and y < M.MAP_SZ
end

---@param x number
---@param y number
---@return boolean
function M.validHeightMapCoord(x, y)
  return x >= 0 and y >= 0 and x < M.HMAP_SZ and y < M.HMAP_SZ
end

---@param x number
---@param y number
---@return number
function M.getHeight(x, y)
  if not M.validHeightMapCoord(x, y) then return 0 end
  return M.heightMap[M.toHeightMapIndex(x, y)]
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
  local px = (x - y) * M.TILE_HW
  local py = (x + y) * M.TILE_HH
  return px, py
end

---@param x number
---@param y number
---@return number, number
function M.worldToGridFloat(x, y)
  local gx = (x / M.TILE_HW + y / M.TILE_HH) / 2
  local gy = (y / M.TILE_HH - x / M.TILE_HW) / 2
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
---@return number, number
function M.snapToGridPoint(x, y)
  local fx, fy = M.worldToGridFloat(x, y)
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
  return M.tiles[M.toTileMapIndex(x, y)]
end

---@param x number
---@param y number
---@return number
function M.getHeightPattern(x, y)
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
function M.updateTileQuad(x, y)
  if not M.validTileCoord(x, y) then return end
  local pattern = M.getHeightPattern(x, y)
  local tile = M.getTile(x, y)
  local h = M.getMinHeight(x, y)
  tile.hy = h * 8
  tile.texInfo = resource.patternToTexInfo(pattern)
end

---@param x number
---@param y number
function M.smoothTerrain(x, y)
  local h1 = M.getHeight(x, y)
  for _, v in ipairs(M.adjacentPositions) do
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
  M.tiles = {}
  M.heightMap = {}
  for _ = 1, M.MAP_SZ * M.MAP_SZ do
    table.insert(M.tiles, M.newTile("grass"))
  end
  for _ = 1, M.HMAP_SZ * M.HMAP_SZ do
    table.insert(M.heightMap, 0)
  end
end

function M.draw()
  for y = 0, M.MAP_SZ - 1 do
    for x = 0, M.MAP_SZ - 1 do
      local px, py = M.gridToWorld(x, y)
      px = px - M.TILE_HW
      local tile = M.getTile(x, y)
      if tile then
        local texInfo = tile.texInfo
        py = py + texInfo.oy - tile.hy
        love.graphics.draw(resource.texture, texInfo.quad, px, py)
      end
    end
  end
end

---@param x number
---@param y number
---@param h number
function M.setTerrainHeight(x, y, h)
  if not M.validHeightMapCoord(x, y) then return end
  if h < 0 or h > 12 then return end
  local i = M.toHeightMapIndex(x, y)
  M.heightMap[i] = h
  M.smoothTerrain(x, y)
  M.updateTileQuad(x, y)
  M.updateTileQuad(x - 1, y)
  M.updateTileQuad(x - 1, y - 1)
  M.updateTileQuad(x, y - 1)
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
