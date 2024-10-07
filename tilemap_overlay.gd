extends Node2D

const Player = preload("res://player.gd")
const Tile = preload("res://tile.gd")

@onready var tilemap = $"../TileMapLayerMain"
var borders : Dictionary
var drawer : Callable
		
func get_tile_points(coord : Vector2i):
	var radius = tilemap.tile_set.tile_size.x / 2
	var o = tilemap.map_to_local(coord)
	var points = []
	for i in 6:
		var rad = deg_to_rad(i * 60)
		var p = Vector2(cos(rad), sin(rad)) * radius
		p.y /= (1.7320508071569 * 0.5)
		points.append(o + p)
	return points
	
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
			#draw_string(ThemeDB.fallback_font, tilemap.map_to_local(coord) , tile.label)
			
	if Game.hovering_tile.x != -1 && Game.hovering_tile.y != -1:
		var points = get_tile_points(Game.hovering_tile)
		var color = Color(0.0, 0.0, 0.0, 0.3)
		draw_line(points[0], points[1], color, 4.0)
		draw_line(points[1], points[2], color, 4.0)
		draw_line(points[2], points[3], color, 4.0)
		draw_line(points[3], points[4], color, 4.0)
		draw_line(points[4], points[5], color, 4.0)
		draw_line(points[5], points[0], color, 4.0)
		

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
	var border = []
	var main_player = Game.players[0] as Player
	var player = Game.players[player_id] as Player
	for c in player.territories:
		if main_player.vision.has(c):
			var points = get_tile_points(c)
			add_line_to_border(border, points[0], points[1])
			add_line_to_border(border, points[1], points[2])
			add_line_to_border(border, points[2], points[3])
			add_line_to_border(border, points[3], points[4])
			add_line_to_border(border, points[4], points[5])
			add_line_to_border(border, points[5], points[0])
	borders[player_id] = border
	queue_redraw()
