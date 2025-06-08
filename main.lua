-- Debugging requires the Local Debugger VSCode extension
if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

local game = require "game"

local function hotReload()
  package.loaded.game = nil
  collectgarbage("collect")
  game = require "game"
  game.load()
end

function love.load()
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
