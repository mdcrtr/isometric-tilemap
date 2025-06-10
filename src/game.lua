local C = require "constants"
local camera = require "camera"
local tileMap = require "tilemap"
local tool = require "tool"

local game = {}

---Loads the game.
function game.load()
  camera.pan(0, 0)
  camera.setScale(1)
  tileMap.init()
end

---Updates the game.
---@param dt number Delta time
function game.update(dt)
  local panAmount = C.PAN_SPEED * dt
  if love.keyboard.isDown("a") then
    camera.pan(panAmount, 0)
  end
  if love.keyboard.isDown("d") then
    camera.pan(-panAmount, 0)
  end
  if love.keyboard.isDown("w") then
    camera.pan(0, panAmount)
  end
  if love.keyboard.isDown("s") then
    camera.pan(0, -panAmount)
  end

  tool.update(dt)
end

---Draws the game.
function game.draw()
  love.graphics.setColor(1, 1, 1)
  camera.apply()

  tileMap.draw()
  tool.draw()

  love.graphics.origin()
  love.graphics.print(tool.getName(), 10, 10)
end

---Handles key pressed event.
---@param key love.KeyConstant Key
function game.keypressed(key)
  if key == "q" then
    camera.zoomOut()
  elseif key == "e" then
    camera.zoomIn()
  elseif key == "j" then
    tool.select("lower")
  elseif key == "k" then
    tool.select("raise")
  elseif key == "l" then
    tool.select("level")
  elseif key == "t" then
    tool.select("tree")
  elseif key == "y" then
    tool.select("house")
  elseif key == "x" then
    tool.select("remove")
  end
end

---Handles mouse pressed event.
---@param x number Mouse X screen position
---@param y number Mouse Y screen position
---@param button number Button index
function game.mousepressed(x, y, button)
  if button == 1 then
    local worldX, worldY = camera.screenToWorld(x, y)
    tool.mousepressed(worldX, worldY)
  end
end

---Handles mouse released event.
---@param x number Mouse X screen position
---@param y number Mouse Y screen position
---@param button number Button index
function game.mousereleased(x, y, button)
  if button == 1 then
    local worldX, worldY = camera.screenToWorld(x, y)
    tool.mousereleased(worldX, worldY)
  end
end

---Handles mouse moved event.
---@param x number Mouse X screen position
---@param y number Mouse Y screen position
function game.mousemoved(x, y)
  local worldX, worldY = camera.screenToWorld(x, y)
  tool.mousemoved(worldX, worldY)
end

return game
