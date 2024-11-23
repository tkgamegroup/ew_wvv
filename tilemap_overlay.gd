extends Node2D

const Player = preload("res://player.gd")
const img_neutral_camp = preload("res://icons/neutral_camp.png")

@onready var tilemap = $"../TileMapLayerMain"
var border_lines : Array
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

func add_line_to_border(lines : Array, p0 : Vector2, p1 : Vector2):
	var n = lines.size() / 2
	for i in n:
		if p0.distance_to(lines[i * 2]) < 0.1 && p1.distance_to(lines[i * 2 + 1]) < 0.1:
			lines.remove_at(i * 2)
			lines.remove_at(i * 2)
			return
		if p1.distance_to(lines[i * 2]) < 0.1 && p0.distance_to(lines[i * 2 + 1]) < 0.1:
			lines.remove_at(i * 2)
			lines.remove_at(i * 2)
			return
	lines.append(p0)
	lines.append(p1)
	
func update_border():
	border_lines = []
	var player = Game.player
	"""
	for c in player.territories:
		var points = get_tile_points(c)
		add_line_to_border(border_lines, points[0], points[1])
		add_line_to_border(border_lines, points[1], points[2])
		add_line_to_border(border_lines, points[2], points[3])
		add_line_to_border(border_lines, points[3], points[4])
		add_line_to_border(border_lines, points[4], points[5])
		add_line_to_border(border_lines, points[5], points[0])
	"""
	queue_redraw()
	
func _draw() -> void:
	var n = border_lines.size() / 2
	for i in n:
		draw_dashed_line(border_lines[i * 2 + 0], border_lines[i * 2 + 1], Game.player.color, 4.0, 8.0)
	
	for x in Game.cx:
		for y in Game.cy:
			var coord = Vector2i(x, y)
			var tile = Game.map[coord] as Tile
			var pos = tilemap.map_to_local(tile.coord)
			#draw_string(ThemeDB.fallback_font, tilemap.map_to_local(coord), "%d,%d" % [tile.coord.x, tile.coord.y])
			
	if Game.hovering_tile.x != -1 && Game.hovering_tile.y != -1:
		var points = get_tile_points(Game.hovering_tile)
		var color = Color(1.0, 1.0, 0.3, 0.3)
		draw_line(points[0], points[1], color, 4.0)
		draw_line(points[1], points[2], color, 4.0)
		draw_line(points[2], points[3], color, 4.0)
		draw_line(points[3], points[4], color, 4.0)
		draw_line(points[4], points[5], color, 4.0)
		draw_line(points[5], points[0], color, 4.0)
