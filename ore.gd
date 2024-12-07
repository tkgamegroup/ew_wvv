extends Node2D

class_name Ore

var type : int
var hp : int
var max_hp : int
var last_minerals_hp : int
var fragile : bool = false
var acid : int = 0
var coord : Vector2i

@onready var sprite : Sprite2D = $Sprite2D

func set_fragile():
	if fragile:
		return
	fragile = true
	var mat : ShaderMaterial = $Sprite2D.material
	mat.set_shader_parameter("fragile", 1.0)

func add_acid(v : int):
	acid += v
	if acid > 0:
		var mat : ShaderMaterial = $Sprite2D.material
		mat.set_shader_parameter("acid", 1.0)

func setup(_type : int, _coord : Vector2i):
	type = _type
	max_hp = 6 * 4
	hp = max_hp
	last_minerals_hp = hp
	
	coord = _coord
	position = Game.tilemap.to_global(Game.tilemap.map_to_local(coord))
	scale = Vector2(0.5, 0.5)
	
func _ready() -> void:
	var mat : ShaderMaterial = $Sprite2D.material
	if type == Game.Gold:
		sprite.texture = load("res://icons/gold_ore.png")
		mat.set_shader_parameter("shininess_mask_texture", load("res://icons/gold_ore_shininess_mask.png"))
	elif type == Game.Ruby:
		sprite.texture = load("res://icons/ruby_ore.png")
		mat.set_shader_parameter("shininess_mask_texture", load("res://icons/ruby_ore_shininess_mask.png"))
	elif type == Game.Emerald:
		sprite.texture = load("res://icons/emerald_ore.png")
		mat.set_shader_parameter("shininess_mask_texture", load("res://icons/emerald_ore_shininess_mask.png"))
	elif type == Game.Sapphire:
		sprite.texture = load("res://icons/sapphire_ore.png")
		mat.set_shader_parameter("shininess_mask_texture", load("res://icons/sapphire_ore_shininess_mask.png"))
	elif type == Game.Amethyst:
		sprite.texture = load("res://icons/amethyst_ore.png")
		mat.set_shader_parameter("shininess_mask_texture", load("res://icons/amethyst_ore_shininess_mask.png"))
	mat.set_shader_parameter("shininess_offset", randf())
