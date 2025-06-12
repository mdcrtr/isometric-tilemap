local C = require "constants"
local resource = require "resource"
local tileMap = require "tilemap"
local util = require "util"

local CREATURE_SPEED = 0.1

---@type Creature[]
local creatures = {}


local function setRandomTarget(creature)
  local dx = math.random(-1, 1)
  local dy = math.random(-1, 1)
  local newX = util.clamp(creature.x + dx, 0, C.MAP_SZ - 1)
  local newY = util.clamp(creature.y + dy, 0, C.MAP_SZ - 1)
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
    name = "creature",
    sprite = resource.atlas.creature
  }
  table.insert(creatures, creature)
end

---Update all creatures
---@param dt number
function M.updateCreatures(dt)
  local distance = CREATURE_SPEED * dt
  for _, creature in ipairs(creatures) do
    if creature.x ~= creature.targetX or creature.y ~= creature.targetY then
      creature.x = util.moveTowards(creature.x, creature.targetX, distance)
      creature.y = util.moveTowards(creature.y, creature.targetY, distance)
    else
      -- If the creature is at its target, set a new random adjacent target
      setRandomTarget(creature)
    end
  end
end

---Draw all creatures
function M.drawCreatures()
  for _, creature in ipairs(creatures) do
    local px, py = tileMap.gridToWorld(creature.x, creature.y)
    local h = tileMap.getMaxHeight(math.floor(creature.x), math.floor(creature.y))
    py = py + creature.sprite.oy - h * C.TILE_HH - 4
    px = px - 4
    love.graphics.draw(resource.texture, creature.sprite.quad, px, py)
  end
end

return M
