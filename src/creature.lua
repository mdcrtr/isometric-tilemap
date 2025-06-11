local C = require "constants"
local resource = require "resource"
local tileMap = require "tilemap"

local CREATURE_SPEED = 0.1

---@type Creature[]
local creatures = {}

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function clamp(value, min, max)
  if value < min then return min end
  if value > max then return max end
  return value
end

local function setRandomTarget(creature)
  local dx = math.random(-1, 1)
  local dy = math.random(-1, 1)
  local newX = clamp(creature.x + dx, 0, C.MAP_SZ - 1)
  local newY = clamp(creature.y + dy, 0, C.MAP_SZ - 1)
  creature.targetX = newX
  creature.targetY = newY
end

local M = {}

---Add a creature
---@param gridX number
---@param gridY number
function M.addCreature(gridX, gridY)
  local creature = {
    x = gridX,
    y = gridY,
    targetX = gridX,
    targetY = gridY,
    t = 0,
    name = "creature",
    sprite = resource.atlas.creature
  }
  table.insert(creatures, creature)
end

---Update all creatures
---@param dt number
function M.updateCreatures(dt)
  local speed = CREATURE_SPEED * dt
  for _, creature in ipairs(creatures) do
    if creature.x ~= creature.targetX or creature.y ~= creature.targetY then
      creature.t = creature.t + speed
      if creature.t >= 1 then
        creature.x = creature.targetX
        creature.y = creature.targetY
      else
        creature.x = lerp(creature.x, creature.targetX, creature.t)
        creature.y = lerp(creature.y, creature.targetY, creature.t)
      end
    else
      -- If the creature is at its target, set a new random adjacent target
      setRandomTarget(creature)
      creature.t = 0
    end
  end
end

---Draw all creatures
function M.drawCreatures()
  for _, creature in ipairs(creatures) do
    local px, py = tileMap.gridToWorld(creature.x, creature.y)
    local h = tileMap.getMaxHeight(math.floor(creature.x), math.floor(creature.y))
    py = py + creature.sprite.oy - h * C.TILE_HH
    love.graphics.draw(resource.texture, creature.sprite.quad, px, py)
  end
end

return M
