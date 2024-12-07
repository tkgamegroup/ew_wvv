extends Node2D

class_name Building

static var config : ConfigFile = null

var building_name : String
var defense : int
var display_name : String
var description : String
var icon : String
var effect : Dictionary
var coord : Vector2i
var shield : bool = false

@onready var sprite : Sprite2D = $Sprite2D

static func get_need_terrain_text(need_terrain : Array):
	var need_terrain_text = ""
	for t in need_terrain:
		if !need_terrain_text.is_empty():
			need_terrain_text += ", "
		#need_terrain_text += Tile.get_terrain_text(t)
	return need_terrain_text

static func get_info(name : String):
	if !config:
		config = ConfigFile.new()
		config.load("res://buildings.ini")
	var ret = {}
	ret.cost_production = config.get_value(name, "cost_production")
	ret.cost_gold = config.get_value(name, "cost_gold")
	ret.need_terrain = config.get_value(name, "need_terrain")
	ret.display_name = config.get_value(name, "display_name")
	ret.description = config.get_value(name, "description")
	ret.icon = config.get_value(name, "icon")
	ret.effect = config.get_value(name, "effect", {})
	return ret

func setup(key : String, _coord : Vector2i):
	var info = get_info(key)
	building_name = key
	display_name = info.display_name
	description = info.description
	icon = info.icon
	effect = info.effect
	
	coord = _coord

func _ready() -> void:
	sprite.texture = load(icon)
	position = Game.tilemap.to_global(Game.tilemap.map_to_local(coord))
