---@meta
--- This file contains type definitions for use with Sumneko's Lua Language Server

---A Two dimensional Vector
---@class Vec
---@field x number X value
---@field y number Y value

---Stores texture coordinates for a tile
---@class TexInfo
---@field name string Name of the texture coordinates
---@field quad love.Quad The texture coordinates
---@field oy number Texture y offset, so that it aligns with the base of the tile.

---A tile map Tile
---@class Tile
---@field texInfo TexInfo Texture coordinates
---@field hy number y offset due to terrain height
---@field structure TexInfo Structure built on tile

---@alias SnapMode "tile" | "vertex"

---@class Tool
---@field name string Name of the tool
---@field snapMode SnapMode How the tool snaps to the grid
---@field use fun() Use the tool at the current tool coordinates

---@class Creature
---@field x number
---@field y number
---@field targetX number
---@field targetY number
---@field t number
---@field name string
---@field sprite TexInfo
