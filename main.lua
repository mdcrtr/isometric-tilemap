-- Debugging requires the Local Debugger VSCode extension
if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

local game = require "game"
local resource = require "resource"

local function hotReload()
  package.loaded.game = nil
  package.loaded.tilemap = nil
  collectgarbage("collect")
  game = require "game"
  game.load()
end

function love.load()
  resource.init()
  game.load()
end

function love.update(dt)
  game.update(dt)
end

function love.draw()
  game.draw()
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  elseif key == "r" then
    hotReload()
  else
    game.keypressed(key)
  end
end

function love.mousepressed(x, y, button)
  game.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
  game.mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
  game.mousemoved(x, y)
end
