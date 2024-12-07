extends Object

class_name Tile

enum
{
	TerrainFloor,
	TerrainFloor2
}

var coord : Vector2i
var terrain : int
var passable : bool = true
var tile_lt : Vector2i
var tile_t : Vector2i
var tile_rt : Vector2i
var tile_lb : Vector2i
var tile_b : Vector2i
var tile_rb : Vector2i
var dist_to_center : int
var building : Building = null
var ore : Ore = null
var monsters : Array[Unit]
var player_units : Array[Unit]
var wet : bool = false

func get_terrain_text():
	if terrain == TerrainFloor:
		if ore:
			match ore.type:
				Game.Ruby:
					return "红宝石矿"
				Game.Emerald:
					return "绿宝石矿"
				Game.Sapphire:
					return "蓝宝石矿"
				Game.Amethyst:
					return "紫水晶矿"
		return "空地"
	elif terrain == TerrainFloor2:
		return "掩埋的"

func _init(_coord : Vector2i, _terrain : int):
	coord = _coord
	terrain = _terrain
	if terrain == TerrainFloor2:
		passable = false
	tile_lt = Vector2i(-1, -1)
	tile_t = Vector2i(-1, -1)
	tile_rt = Vector2i(-1, -1)
	tile_lb = Vector2i(-1, -1)
	tile_b = Vector2i(-1, -1)
	tile_rb = Vector2i(-1, -1)
	
func init_surroundings(map : Dictionary):
	if coord.x % 2 == 0:
		if coord.x > 0 && coord.y > 0:
			var c = Vector2i(coord.x - 1, coord.y - 1)
			if map.has(c):
				tile_lt = c
		if coord.x < Game.cx - 1 && coord.y > 0:
			var c = Vector2i(coord.x + 1, coord.y - 1)
			if map.has(c):
				tile_rt = c
		if coord.x > 0:
			var c = Vector2i(coord.x - 1, coord.y)
			if map.has(c):
				tile_lb = c
		if coord.x < Game.cx - 1:
			var c = Vector2i(coord.x + 1, coord.y)
			if map.has(c):
				tile_rb = c
	else:
		if coord.x > 0:
			var c = Vector2i(coord.x - 1, coord.y)
			if map.has(c):
				tile_lt = c
		if coord.x < Game.cx - 1:
			var c = Vector2i(coord.x + 1, coord.y)
			if map.has(c):
				tile_rt = c
		if coord.x > 0 && coord.y < Game.cy - 1:
			var c = Vector2i(coord.x - 1, coord.y + 1)
			if map.has(c):
				tile_lb = c
		if coord.x < Game.cx - 1 && coord.y < Game.cy - 1:
			var c = Vector2i(coord.x + 1, coord.y + 1)
			if map.has(c):
				tile_rb = c
	if coord.y > 0:
			var c = Vector2i(coord.x, coord.y - 1)
			if map.has(c):
				tile_t = c
	if coord.y < Game.cy - 1:
			var c = Vector2i(coord.x, coord.y + 1)
			if map.has(c):
				tile_b = c
