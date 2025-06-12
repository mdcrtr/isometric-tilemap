-- Debugging requires the Local Lua Debugger VSCode extension
if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

package.path = "./src/?.lua;" .. package.path
love.filesystem.setRequirePath("src/?.lua;" .. love.filesystem.getRequirePath())

local game = require "game"
local resource = require "resource"

local function hotReload()
  package.loaded.camera = nil
  package.loaded.constants = nil
  package.loaded.creatures = nil
  package.loaded.game = nil
  package.loaded.tilemap = nil
  package.loaded.tool = nil
  package.loaded.util = nil
  collectgarbage("collect")
  game = require "game"
  game.load()
end

function love.load()
  resource.load()
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
