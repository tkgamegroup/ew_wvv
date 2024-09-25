extends TileMapLayer

signal tile_hovered(coord : Vector2i)

func _ready() -> void:
	pass
	
func set_hovering_tile(coord : Vector2i):
	if Game.hovering_tile.x != coord.x && Game.hovering_tile.y != coord.y:
		if Game.hovering_tile.x >= 0 && Game.hovering_tile.y >= 0:
			set_cell(Game.hovering_tile, 0, Vector2i(0, 0))
		Game.hovering_tile = coord
		if Game.hovering_tile.x >= 0 && Game.hovering_tile.y >= 0:
			set_cell(Game.hovering_tile, 1, Vector2i(0, 0))
		tile_hovered.emit(coord)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var coord = local_to_map(get_local_mouse_position())
		if coord.x >= 0 && coord.x < Game.cx && coord.y >= 0 && coord.y < Game.cy:
			set_hovering_tile(coord)
