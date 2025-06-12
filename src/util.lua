local M = {}

---Clamp a value
---@param value number
---@param min number
---@param max number
---@return number
function M.clamp(value, min, max)
  if value < min then return min end
  if value > max then return max end
  return value
end

---Move towards a target by distance
---@param x number
---@param targetX number
---@param distance number
---@return number
function M.moveTowards(x, targetX, distance)
  local distRemaining = math.abs(targetX - x)
  if distRemaining <= distance then
    return targetX
  end
  if x < targetX then
    return x + distance
  end
  return x - distance
end

return M
