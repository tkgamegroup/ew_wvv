extends TileMapLayer

const Tile = preload("res://tile.gd")
const Player = preload("res://player.gd")

@onready var tilemap_water = $"../TileMapLayerWater"
@onready var tilemap_dirt = $"../TileMapLayerDirt"
@onready var overlay = $"../TileMapOverlay"

signal tile_hovered(coord : Vector2i)

func _ready() -> void:
	pass
	
func set_hovering_tile(coord : Vector2i):
	if Game.hovering_tile.x != coord.x && Game.hovering_tile.y != coord.y:
		Game.hovering_tile = coord
		overlay.queue_redraw()
		tile_hovered.emit(coord)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var coord = local_to_map(get_local_mouse_position())
		if coord.x >= 0 && coord.x < Game.cx && coord.y >= 0 && coord.y < Game.cy:
			if Game.main_player.vision.has(coord):
				set_hovering_tile(coord)
