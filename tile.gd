class_name Tile

enum
{
	TerrainPlain,
	TerrainForest,
	TerrainWater
}

var coord : Vector2i
var terrain : int
var passable : bool = true
var tilemap_atlas_ids : Array
var tilemap_atlas_coords : Array
var tile_lt : Vector2i
var tile_t : Vector2i
var tile_rt : Vector2i
var tile_lb : Vector2i
var tile_b : Vector2i
var tile_rb : Vector2i
var building : String
var player : int = -1
var neutral_units : Array
var resource_type : int
var resource_amount : int

var label : String

static func get_terrain_text(terrain : int):
	if terrain == TerrainPlain:
		return "平原"
	elif terrain == TerrainForest:
		return "森林"
	elif terrain == TerrainWater:
		return "水"

func _init(_coord : Vector2i, _terrain : int):
	coord = _coord
	terrain = _terrain
	if terrain == TerrainWater:
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

func get_neutral_unit_types():
	var dic = {}
	for u in neutral_units:
		var name = u.unit_name
		if dic.has(name):
			dic[name] += 1
		else:
			dic[name] = 1
	return dic

func remove_neutral_unit(name : String):
	for i in neutral_units.size():
		if neutral_units[i].unit_name == name:
			neutral_units.remove_at(i)
			break
