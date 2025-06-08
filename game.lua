---@class Vec
---@field x number
---@field y number

---@class TexInfo
---@field name string
---@field quad love.Quad texture coords
---@field oy number texture y offset

---@class Tile
---@field texInfo TexInfo
---@field hy number y offset due to height

local game = {}

game.MAP_SZ = 32
game.HMAP_SZ = game.MAP_SZ + 1
game.TILE_W = 32
game.TILE_H = 16
game.TILE_HW = game.TILE_W / 2
game.TILE_HH = game.TILE_H / 2
game.texture = nil
game.transform = love.math.newTransform()
game.dbgText = ""
game.toolCooldown = 0
game.tool = "raiseLower"

---@type Tile[]
game.tileMap = {}

---@type number[]
game.heightMap = {}

---@type Vec
game.mousePos = { x = 0, y = 0 }

---@type Vec[]
game.adjacentPositions = {
  { x = -1, y = -1 },
  { x = 0,  y = -1 },
  { x = 1,  y = -1 },
  { x = -1, y = 0 },
  { x = 1,  y = 0 },
  { x = -1, y = 1 },
  { x = 0,  y = 1 },
  { x = 1,  y = 1 },
}

---@param name string
---@param x number
---@param y number
---@param w number
---@param h number
---@param oy number?
---@TexInfo
function game.newTexInfo(name, x, y, w, h, oy)
  return {
    name = name,
    quad = love.graphics.newQuad(x, y, w, h, 256, 256),
    oy = oy or (16 - h)
  }
end

---@type TexInfo[]
game.atlas = {
  grass = game.newTexInfo("grass", 32, 0, 32, 16),
  slopeSW = game.newTexInfo("slopeSW", 0, 16, 32, 32),
  slopeS = game.newTexInfo("slopeS", 32, 16, 32, 32),
  slopeSE = game.newTexInfo("slopeSE", 64, 16, 32, 32),
  slopeE = game.newTexInfo("slopeE", 96, 16, 32, 32),
  slopeNE = game.newTexInfo("slopeNE", 0, 48, 32, 32),
  slopeN = game.newTexInfo("slopeN", 32, 48, 32, 32),
  slopeNW = game.newTexInfo("slopeNW", 64, 48, 32, 32),
  slopeW = game.newTexInfo("slopeW", 96, 48, 32, 32),
  slopeNESW = game.newTexInfo("slopeNESW", 128, 48, 32, 32),
  dipNW = game.newTexInfo("dipNW", 0, 80, 32, 16, -8),
  dipSW = game.newTexInfo("dipSW", 32, 80, 32, 32, -8),
  dipSE = game.newTexInfo("dipSE", 64, 80, 32, 32, -8),
  dipNE = game.newTexInfo("dipNE", 96, 80, 32, 32, -8),
}

-- SW, SE, NE, NW
---@type string[]
game.patternToAltas = {
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

---@param texName string
---@return Tile
function game.newTile(texName)
  return {
    texInfo = game.atlas[texName],
    hy = 0
  }
end

---@param x number
---@param y number
---@return number
function game.toTileMapIndex(x, y)
  return y * game.MAP_SZ + x + 1
end

---@param x number
---@param y number
---@return number
function game.toHeightMapIndex(x, y)
  return y * game.HMAP_SZ + x + 1
end

---@param x number
---@param y number
---@return boolean
function game.validTileCoord(x, y)
  return x >= 0 and y >= 0 and x < game.MAP_SZ and y < game.MAP_SZ
end

---@param x number
---@param y number
---@return boolean
function game.validHeightMapCoord(x, y)
  return x >= 0 and y >= 0 and x < game.HMAP_SZ and y < game.HMAP_SZ
end

---@param x number
---@param y number
---@return number
function game.getHeight(x, y)
  if not game.validHeightMapCoord(x, y) then return 0 end
  return game.heightMap[game.toHeightMapIndex(x, y)]
end

---@param x number
---@param y number
---@return number
function game.getMinHeight(x, y)
  return math.min(
    game.getHeight(x, y), game.getHeight(x + 1, y),
    game.getHeight(x + 1, y + 1), game.getHeight(x, y + 1)
  )
end

---@param x number
---@param y number
---@return number, number
function game.screenToWorld(x, y)
  return game.transform:inverseTransformPoint(x, y)
end

---@param x number
---@param y number
---@return number, number
function game.gridToWorld(x, y)
  local px = (x - y) * game.TILE_HW
  local py = (x + y) * game.TILE_HH
  return px, py
end

---@param x number
---@param y number
---@return number, number
function game.worldToGridFloat(x, y)
  local gx = (x / game.TILE_HW + y / game.TILE_HH) / 2
  local gy = (y / game.TILE_HH - x / game.TILE_HW) / 2
  return gx, gy
end

---@param x number
---@param y number
---@return number, number
function game.worldToGrid(x, y)
  local gx, gy = game.worldToGridFloat(x, y)
  return math.floor(gx), math.floor(gy)
end

---@param x number
---@param y number
---@return number, number
function game.snapToGridPoint(x, y)
  local fx, fy = game.worldToGridFloat(x, y)
  local startX = math.floor(fx)
  local startY = math.floor(fy)
  local closestX = startX
  local closestY = startY
  local closestDist = 999999

  local function checkPoint(gx, gy)
    local h = game.getHeight(gx, gy)
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
function game.getTile(x, y)
  if not game.validTileCoord(x, y) then return nil end
  return game.tileMap[game.toTileMapIndex(x, y)]
end

---@param x number
---@param y number
---@return number
function game.getHeightPattern(x, y)
  local heights = {
    game.getHeight(x, y),
    game.getHeight(x + 1, y),
    game.getHeight(x + 1, y + 1),
    game.getHeight(x, y + 1),
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
function game.updateTileQuad(x, y)
  if not game.validTileCoord(x, y) then return end
  local pattern = game.getHeightPattern(x, y)
  local atlasName = game.patternToAltas[pattern]
  local tile = game.tileMap[game.toTileMapIndex(x, y)]
  local h = game.getMinHeight(x, y)
  tile.hy = h * 8
  tile.texInfo = game.atlas[atlasName]
end

---@param x number
---@param y number
function game.smoothTerrain(x, y)
  local h1 = game.getHeight(x, y)
  for _, v in ipairs(game.adjacentPositions) do
    local nx = x + v.x
    local ny = y + v.y
    if game.validHeightMapCoord(nx, ny) then
      local h2 = game.getHeight(nx, ny)
      if h2 - h1 > 1 then
        game.raiseLowerTerrain(nx, ny, -1)
      elseif h1 - h2 > 1 then
        game.raiseLowerTerrain(nx, ny, 1)
      end
    end
  end
end

---@param x number
---@param y number
---@param dh number
function game.raiseLowerTerrain(x, y, dh)
  if not game.validHeightMapCoord(x, y) then return end
  local i = game.toHeightMapIndex(x, y)
  game.heightMap[i] = game.heightMap[i] + dh
  game.smoothTerrain(x, y)
  game.updateTileQuad(x, y)
  game.updateTileQuad(x - 1, y)
  game.updateTileQuad(x - 1, y - 1)
  game.updateTileQuad(x, y - 1)
end

---@param x number
---@param y number
---@param h number
function game.setTerrainHeight(x, y, h)
  if not game.validHeightMapCoord(x, y) then return end
  local i = game.toHeightMapIndex(x, y)
  game.heightMap[i] = h
  game.smoothTerrain(x, y)
  game.updateTileQuad(x, y)
  game.updateTileQuad(x - 1, y)
  game.updateTileQuad(x - 1, y - 1)
  game.updateTileQuad(x, y - 1)
end

function game.load()
  game.transform:translate(500, 200)
  game.transform:scale(4)
  game.texture = love.graphics.newImage("assets/iso-tiles2.png")
  game.texture:setFilter("nearest", "nearest")
  for _ = 1, game.MAP_SZ * game.MAP_SZ do
    table.insert(game.tileMap, game.newTile("grass"))
  end
  for _ = 1, game.HMAP_SZ * game.HMAP_SZ do
    table.insert(game.heightMap, 0)
  end
end

function game.update(dt)
  if game.toolCooldown > 0 then
    game.toolCooldown = game.toolCooldown - dt
  end

  if love.keyboard.isDown("a") then
    game.transform:translate(4, 0)
  end
  if love.keyboard.isDown("d") then
    game.transform:translate(-4, 0)
  end
  if love.keyboard.isDown("w") then
    game.transform:translate(0, 4)
  end
  if love.keyboard.isDown("s") then
    game.transform:translate(0, -4)
  end

  game.mousePos.x, game.mousePos.y = game.screenToWorld(love.mouse.getPosition())
  local gridX, gridY = game.snapToGridPoint(game.mousePos.x, game.mousePos.y)

  if game.toolCooldown <= 0 and game.validHeightMapCoord(gridX, gridY) then
    if game.tool == "raiseLower" then
      if love.mouse.isDown(1) then
        game.raiseLowerTerrain(gridX, gridY, 1)
        game.toolCooldown = 0.2
      elseif love.mouse.isDown(2) then
        game.raiseLowerTerrain(gridX, gridY, -1)
        game.toolCooldown = 0.2
      end
    elseif game.tool == "level" then
      if love.mouse.isDown(1) then
        game.setTerrainHeight(gridX, gridY, 1)
        game.toolCooldown = 0.2
      end
    end
  end
end

function game.draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.applyTransform(game.transform)
  for y = 0, game.MAP_SZ - 1 do
    for x = 0, game.MAP_SZ - 1 do
      local px, py = game.gridToWorld(x, y)
      px = px - game.TILE_HW
      local tile = game.getTile(x, y)
      if tile then
        local texInfo = tile.texInfo
        py = py + texInfo.oy - tile.hy
        love.graphics.draw(game.texture, texInfo.quad, px, py)
      end
    end
  end

  local gridX, gridY = game.snapToGridPoint(game.mousePos.x, game.mousePos.y)
  local height = game.getHeight(gridX, gridY)
  local wx, wy = game.gridToWorld(gridX, gridY)
  wy = wy - height * 8
  love.graphics.setColor(1, 1, 0)
  love.graphics.circle("fill", wx, wy, 2)
  love.graphics.origin()
  love.graphics.print(game.dbgText, 10, 10)
  love.graphics.print(game.tool, 200, 10)
end

function game.keypressed(key)
  if key == "q" then
    game.transform:scale(0.5)
  elseif key == "e" then
    game.transform:scale(2)
  elseif key == "k" then
    game.tool = "raiseLower"
  elseif key == "l" then
    game.tool = "level"
  end
end

function game.mousepressed(x, y, button)
end

return game
