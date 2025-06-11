local C = require "constants"
local creature = require "creature"
local tileMap = require "tilemap"

local toolX = 0
local toolY = 0
local mouseDown = false
local refHeight = 0

---Snaps World position to Grid coordinates.
---Updates tool coordinates.
---@param worldX number World X position
---@param worldY number World Y position
---@param snapMode SnapMode Snap to the tile or vertex
---@param useRefHeight boolean Snap to the reference height, instead of terrain height
local function setToolPos(worldX, worldY, snapMode, useRefHeight)
  if snapMode == "vertex" then
    if useRefHeight then
      toolX, toolY = tileMap.snapToFixedHeightGrid(worldX, worldY, refHeight)
    else
      toolX, toolY = tileMap.snapToGridPoint(worldX, worldY)
    end
  else
    _, _, toolX, toolY = tileMap.snapToGridPoint(worldX, worldY)
  end
end

---@type {[string]: Tool}
local toolRegistry = {
  idle = {
    name = "idle",
    snapMode = "tile",
    use = function() end
  },
  raise = {
    name = "raise",
    snapMode = "vertex",
    use = function()
      tileMap.raiseTerrain(toolX, toolY)
    end
  },
  lower = {
    name = "lower",
    snapMode = "vertex",
    use = function()
      tileMap.lowerTerrain(toolX, toolY)
    end
  },
  level = {
    name = "level",
    snapMode = "vertex",
    use = function()
      tileMap.setTerrainHeight(toolX, toolY, refHeight)
    end
  },
  tree = {
    name = "tree",
    snapMode = "tile",
    use = function()
      tileMap.addStructure(toolX, toolY, "tree")
    end
  },
  house = {
    name = "house",
    snapMode = "tile",
    use = function()
      tileMap.addStructure(toolX, toolY, "house")
    end
  },
  remove = {
    name = "remove",
    snapMode = "tile",
    use = function()
      tileMap.removeStucture(toolX, toolY)
    end
  },
  creature = {
    name = "creature",
    snapMode = "tile",
    use = function()
      creature.addCreature(toolX, toolY)
    end
  }
}

local tool = toolRegistry.idle ---@type Tool

local M = {}

---Selects a tool.
---@param toolName string The tool name
function M.select(toolName)
  if toolRegistry[toolName] then
    tool = toolRegistry[toolName]
  else
    tool = toolRegistry.idle
  end
end

---Gets the selected tool.
---@return string - The tool name
function M.getName()
  return tool.name
end

---Performs per-frame tool update.
---@param dt number Delta time
function M.update(dt)
end

---Performs per-frame tool drawing.
function M.draw()
  local height = tileMap.getHeight(toolX, toolY)
  local worldX, worldY = tileMap.gridToWorld(toolX, toolY)
  worldY = worldY - height * C.TILE_HH
  love.graphics.setColor(1, 1, 0)
  love.graphics.circle("fill", worldX, worldY, 2)
end

---Handles mouse pressed event.
---@param worldX number World X position
---@param worldY number World Y position
function M.mousepressed(worldX, worldY)
  setToolPos(worldX, worldY, tool.snapMode, false)
  refHeight = tileMap.getHeight(toolX, toolY)
  mouseDown = true
  tool.use()
end

---Handles mouse released event.
---@param worldX number World X position
---@param worldY number World Y position
function M.mousereleased(worldX, worldY)
  setToolPos(worldX, worldY, tool.snapMode, true)
  mouseDown = false
end

---Handles mouse moved event.
---@param worldX number World X position
---@param worldY number World Y position
function M.mousemoved(worldX, worldY)
  local oldX, oldY = toolX, toolY

  -- When using the tool, snap to the fixed reference height to prevent it
  -- jumping up and down the terrain while the user is trying to move the tool.
  setToolPos(worldX, worldY, tool.snapMode, mouseDown)
  if oldX == toolX and oldY == toolY then return end

  if mouseDown then
    tool.use()
  end
end

return M
