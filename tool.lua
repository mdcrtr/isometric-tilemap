local tileMap = require "tilemap"

local tool = "raise"
local toolX = 0
local toolY = 0
local mouseDown = false
local refHeight = 0

local function setToolPos(worldX, worldY, useRefHeight)
  local fixedHeight = nil
  if useRefHeight then
    fixedHeight = refHeight
  end
  toolX, toolY = tileMap.snapToGridPoint(worldX, worldY, fixedHeight)
end

local function useTool()
  if tool == "raise" then
    tileMap.raiseTerrain(toolX, toolY)
  elseif tool == "lower" then
    tileMap.lowerTerrain(toolX, toolY)
  elseif tool == "level" then
    tileMap.setTerrainHeight(toolX, toolY, refHeight)
  end
end

local M = {}

function M.select(toolName)
  tool = toolName
end

function M.getName()
  return tool
end

function M.update(dt)
end

function M.draw()
  local height = tileMap.getHeight(toolX, toolY)
  local worldX, worldY = tileMap.gridToWorld(toolX, toolY)
  worldY = worldY - height * 8
  love.graphics.setColor(1, 1, 0)
  love.graphics.circle("fill", worldX, worldY, 2)
end

function M.mousepressed(worldX, worldY)
  setToolPos(worldX, worldY, false)
  refHeight = tileMap.getHeight(toolX, toolY)
  mouseDown = true
  useTool()
end

function M.mousereleased(worldX, worldY)
  setToolPos(worldX, worldY, true)
  mouseDown = false
end

function M.mousemoved(worldX, worldY)
  local oldX, oldY = toolX, toolY
  setToolPos(worldX, worldY, mouseDown)
  if oldX == toolX and oldY == toolY then return end

  if mouseDown then
    useTool()
  end
end

return M
