local resource = require "resource"
local tileMap = require "tilemap"

local game = {}

game.transform = love.math.newTransform()
game.dbgText = ""
game.toolCooldown = 0
game.tool = "raiseLower"
game.mousePos = { x = 0, y = 0 } ---@type Vec

---@param x number
---@param y number
---@return number, number
function game.screenToWorld(x, y)
  return game.transform:inverseTransformPoint(x, y)
end

function game.load()
  game.transform:translate(500, 200)
  game.transform:scale(4)
  tileMap.init()
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
  local gridX, gridY = tileMap.snapToGridPoint(game.mousePos.x, game.mousePos.y)

  if game.toolCooldown <= 0 and tileMap.validHeightMapCoord(gridX, gridY) then
    if game.tool == "raiseLower" then
      if love.mouse.isDown(1) then
        tileMap.raiseTerrain(gridX, gridY)
        game.toolCooldown = 0.2
      elseif love.mouse.isDown(2) then
        tileMap.lowerTerrain(gridX, gridY)
        game.toolCooldown = 0.2
      end
    elseif game.tool == "level" then
      if love.mouse.isDown(1) then
        tileMap.setTerrainHeight(gridX, gridY, 1)
        game.toolCooldown = 0.2
      end
    end
  end
end

function game.draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.applyTransform(game.transform)
  tileMap.draw()

  local gridX, gridY = tileMap.snapToGridPoint(game.mousePos.x, game.mousePos.y)
  local height = tileMap.getHeight(gridX, gridY)
  local wx, wy = tileMap.gridToWorld(gridX, gridY)
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
