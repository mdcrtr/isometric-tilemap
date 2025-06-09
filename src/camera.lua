local C = require "constants"

local offsetX = 0
local offsetY = 0
local zoom = 1
local transform = love.math.newTransform()

---Updates the view transform.
local function updateTransform()
  local topLeftX = offsetX + love.graphics.getWidth() / 2
  local topLeftY = offsetY + love.graphics.getHeight() / 2
  transform:reset():translate(topLeftX, topLeftY):scale(zoom)
end

---Zooms by a factor
---@param factor number Relative zoom factor
local function zoomRelative(factor)
  zoom = zoom * factor
  offsetX = offsetX * factor
  offsetY = offsetY * factor
  updateTransform()
end

local M = {}

---Resets the camera.
function M.reset()
  offsetX = 0
  offsetY = 0
  zoom = 1
end

---Pans the camera.
---@param dx number Relative X movement
---@param dy number Relative Y movement
function M.pan(dx, dy)
  offsetX = offsetX + dx
  offsetY = offsetY + dy
  updateTransform()
end

---Sets the absolute camera zoom.
---@scale number The absolute zoom
function M.setScale(scale)
  if scale < C.MIN_ZOOM then
    zoom = C.MIN_ZOOM
  elseif scale > C.MAX_ZOOM then
    zoom = C.MAX_ZOOM
  else
    zoom = scale
  end
  updateTransform()
end

---Zooms in.
function M.zoomIn()
  if zoom * 2 > C.MAX_ZOOM then return end
  zoomRelative(2)
end

---Zooms out.
function M.zoomOut()
  if zoom * 0.5 < C.MIN_ZOOM then return end
  zoomRelative(0.5)
end

---Gets the camera transform
---@return love.Transform
function M.getTransform()
  return transform
end

---Applies the camera transform to the graphics context.
function M.apply()
  love.graphics.applyTransform(transform)
end

---Converts Screen position to World position.
---@param x number Screen X position
---@param y number Screen Y position
---@return number, number - World X/Y position
function M.screenToWorld(x, y)
  return transform:inverseTransformPoint(x, y)
end

return M
