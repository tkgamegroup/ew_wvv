extends Node2D

class_name Ore

enum
{
	GoldOre,
	RubyOre,
	EmeraldOre,
	SapphireOre,
	AmethystOre
}

var type : int
var hp : int
var max_hp : int
var fragile = false
var coord : Vector2i

@onready var sprite : Sprite2D = $Sprite2D

func set_fragile():
	fragile = true
	var mat : ShaderMaterial = $Sprite2D.material
	mat.set_shader_parameter("fragile_value", 1.0)

func setup(_type : int, _coord : Vector2i):
	type = _type
	max_hp = 6 * 4
	hp = max_hp
	
	coord = _coord
	position = Game.tilemap.to_global(Game.tilemap.map_to_local(coord))
	scale = Vector2(0.5, 0.5)
	
func _ready() -> void:
	var mat : ShaderMaterial = $Sprite2D.material
	if type == GoldOre:
		sprite.texture = load("res://icons/gold_ore.png")
		mat.set_shader_parameter("shininess_mask_texture", load("res://icons/gold_ore_shininess_mask.png"))
	elif type == RubyOre:
		sprite.texture = load("res://icons/ruby_ore.png")
		mat.set_shader_parameter("shininess_mask_texture", load("res://icons/ruby_ore_shininess_mask.png"))
	elif type == EmeraldOre:
		sprite.texture = load("res://icons/emerald_ore.png")
		mat.set_shader_parameter("shininess_mask_texture", load("res://icons/emerald_ore_shininess_mask.png"))
	elif type == SapphireOre:
		sprite.texture = load("res://icons/sapphire_ore.png")
		mat.set_shader_parameter("shininess_mask_texture", load("res://icons/sapphire_ore_shininess_mask.png"))
	elif type == AmethystOre:
		sprite.texture = load("res://icons/amethyst_ore.png")
		mat.set_shader_parameter("shininess_mask_texture", load("res://icons/amethyst_ore_shininess_mask.png"))
	mat.set_shader_parameter("shininess_offset", randf())
