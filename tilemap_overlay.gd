extends Node2D

const Player = preload("res://player.gd")
const Tile = preload("res://tile.gd")

var tilemap : TileMapLayer
var borders : Dictionary
var drawer : Callable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tilemap = $"../TileMapLayer"
	
	for id in Game.players:
		var player = Game.players[id] as Player
		player.territory_changed.connect(update_border)
		player.building_changed.connect(func(id):
			queue_redraw()
		)
		update_border(id)
	
func _draw() -> void:
	for id in borders:
		var color = Game.players[id].color
		var b = borders[id]
		var n = b.size() / 2
		for i in n:
			draw_dashed_line(b[i * 2 + 0], b[i * 2 + 1], color, 4.0, 8.0)
	
	if drawer.is_valid():
		drawer.call(self)
	
	for x in Game.cx:
		for y in Game.cy:
			var coord = Vector2i(x, y)
			var tile = Game.map[coord] as Tile
			draw_string(ThemeDB.fallback_font, tilemap.map_to_local(coord) , tile.label)

func _process(delta: float) -> void:
	pass
	
func add_line_to_border(border : Array, p0 : Vector2, p1 : Vector2):
	var n = border.size() / 2
	for i in n:
		if p0.distance_to(border[i * 2]) < 0.1 && p1.distance_to(border[i * 2 + 1]) < 0.1:
			border.remove_at(i * 2)
			border.remove_at(i * 2)
			return
		if p1.distance_to(border[i * 2]) < 0.1 && p0.distance_to(border[i * 2 + 1]) < 0.1:
			border.remove_at(i * 2)
			border.remove_at(i * 2)
			return
	border.append(p0)
	border.append(p1)
	
func update_border(player_id : int):
	var radius = tilemap.tile_set.tile_size.x / 2
	var border = []
	var player = Game.players[player_id] as Player
	for t in player.territories:
		var o = tilemap.map_to_local(t)
		var points = []
		for i in 6:
			var rad = deg_to_rad(i * 60)
			var p = Vector2(cos(rad), sin(rad)) * radius
			p.y /= (1.7320508071569 * 0.5)
			points.append(o + p)
		add_line_to_border(border, points[0], points[1])
		add_line_to_border(border, points[1], points[2])
		add_line_to_border(border, points[2], points[3])
		add_line_to_border(border, points[3], points[4])
		add_line_to_border(border, points[4], points[5])
		add_line_to_border(border, points[5], points[0])
	borders[player_id] = border
	queue_redraw()
