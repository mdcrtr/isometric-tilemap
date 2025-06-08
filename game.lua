local tileMap = require "tilemap"
local tool = require "tool"

local game = {}

game.transform = love.math.newTransform()

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

  tool.update(dt)
end

function game.draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.applyTransform(game.transform)

  tileMap.draw()
  tool.draw()

  love.graphics.origin()
  love.graphics.print(tool.getName(), 10, 10)
end

function game.keypressed(key)
  if key == "q" then
    game.transform:scale(0.5)
  elseif key == "e" then
    game.transform:scale(2)
  elseif key == "j" then
    tool.select("lower")
  elseif key == "k" then
    tool.select("raise")
  elseif key == "l" then
    tool.select("level")
  end
end

function game.mousepressed(x, y, button)
  if button == 1 then
    local worldX, worldY = game.screenToWorld(x, y)
    tool.mousepressed(worldX, worldY)
  end
end

function game.mousereleased(x, y, button)
  if button == 1 then
    local worldX, worldY = game.screenToWorld(x, y)
    tool.mousereleased(worldX, worldY)
  end
end

function game.mousemoved(x, y)
  local worldX, worldY = game.screenToWorld(x, y)
  tool.mousemoved(worldX, worldY)
end

return game
