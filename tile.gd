var tile_lt : Vector2i
var tile_t : Vector2i
var tile_rt : Vector2i
var tile_lb : Vector2i
var tile_b : Vector2i
var tile_rb : Vector2i
var building : String = ""
var player : int = -1
var neutral_units : Array
var production_resource : int = 0

var coord : Vector2i

var label : String

func _init(c : Vector2i):
	coord = c
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
