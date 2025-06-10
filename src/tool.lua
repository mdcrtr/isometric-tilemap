local C         = require "constants"
local tileMap   = require "tilemap"

local tool      = "raise"
local toolX     = 0
local toolY     = 0
local mouseDown = false
local refHeight = 0

---Snaps World position to Grid coordinates.
---Updates tool coordinates.
---@param worldX number World X position
---@param worldY number World Y position
---@param useRefHeight boolean Snap to the reference height, instead of terrain height
local function setToolPos(worldX, worldY, useRefHeight)
  local fixedHeight = nil
  if useRefHeight then
    fixedHeight = refHeight
  end
  toolX, toolY = tileMap.snapToGridPoint(worldX, worldY, fixedHeight)
end

---Use the selected tool at the current tool coordinates.
local function useTool()
  if tool == "raise" then
    tileMap.raiseTerrain(toolX, toolY)
  elseif tool == "lower" then
    tileMap.lowerTerrain(toolX, toolY)
  elseif tool == "level" then
    tileMap.setTerrainHeight(toolX, toolY, refHeight)
  elseif tool == "tree" then
    tileMap.addStructure(toolX, toolY, "tree")
  elseif tool == "house" then
    tileMap.addStructure(toolX, toolY, "house")
  elseif tool == "remove" then
    tileMap.removeStucture(toolX, toolY)
  end
end

local M = {}

---Selects a tool.
---@param toolName string The tool name
function M.select(toolName)
  tool = toolName
end

---Gets the selected tool.
---@return string - The tool name
function M.getName()
  return tool
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
  setToolPos(worldX, worldY, false)
  refHeight = tileMap.getHeight(toolX, toolY)
  mouseDown = true
  useTool()
end

---Handles mouse released event.
---@param worldX number World X position
---@param worldY number World Y position
function M.mousereleased(worldX, worldY)
  setToolPos(worldX, worldY, true)
  mouseDown = false
end

---Handles mouse moved event.
---@param worldX number World X position
---@param worldY number World Y position
function M.mousemoved(worldX, worldY)
  local oldX, oldY = toolX, toolY

  -- When using the tool, snap to the fixed reference height to prevent it
  -- jumping up and down the terrain while the user is trying to move the tool.
  setToolPos(worldX, worldY, mouseDown)
  if oldX == toolX and oldY == toolY then return end

  if mouseDown then
    useTool()
  end
end

return M
