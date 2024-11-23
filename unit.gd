extends Node2D

class_name Unit

const Tile = preload("res://tile.gd")

static var config : ConfigFile = null

var unit_name : String
var display_name : String
var description : String
var icon : String
var atk : int
var hp : int
var max_hp : int
var coord : Vector2i
var is_enemy : bool

var move_tween : Tween = null

@onready var sprite : Sprite2D = $Sprite2D
@onready var health_bar : Control = $HBoxContainer

static func get_info(key : String):
	if !config:
		config = ConfigFile.new()
		config.load("res://units.ini")
	var ret = {}
	ret.display_name = config.get_value(key, "display_name")
	ret.description = config.get_value(key, "description", "")
	ret.description = "ATK: {atk}\nHP: {max_hp}\n" + ret.description
	ret.icon = config.get_value(key, "icon")
	ret.atk = config.get_value(key, "atk")
	ret.max_hp = config.get_value(key, "max_hp")
	return ret

func update_pos():
	var idx = -1
	var tile = Game.map[coord]
	if is_enemy:
		idx = tile.monsters.find(self)
	else:
		idx = tile.player_units.find(self)
		idx += tile.monsters.size()
	var n = tile.monsters.size() + tile.player_units.size()
	var a = 0.0
	var r = 0.0
	if n > 1 && idx < 4:
		r = 15.0
		a = lerp(0.0, PI * 2.0, float(min(n, 4) - idx - 1) / 4.0) + 10.0
	elif n > 4 && idx >= 4 && idx < 10:
		r = 25.0
		a = lerp(0.0, PI * 2.0, float(min(n, 10) - (idx - 4) - 1) / 7.0) + 20.0
	elif n > 10 && idx >= 10 && idx < 25:
		r = 30.0
		a = lerp(0.0, PI * 2.0, float(min(n, 25) - (idx - 10) - 1) / 15.0) + 30.0
	var pos = Game.tilemap.to_global(Game.tilemap.map_to_local(coord))
	pos.x += r * cos(a)
	pos.y += r * sin(a)
	
	if move_tween:
		move_tween.kill()
	move_tween = Game.tree.create_tween()
	move_tween.tween_property(self, "position", pos, 0.35)
	move_tween.tween_callback(func():
		move_tween = null
	)

func update_hp():
	var v = 0
	for n in health_bar.get_children():
		n.get_child(0).size = Vector2(max(hp - v, 0) * 3.0, 8.0)
		v += 4

func take_damage(v : int):
	hp = max(0, hp - v)
	update_hp()
	
	if hp <= 0:
		var pos = Game.tilemap.to_global(Game.tilemap.map_to_local(coord))
		var blood_sprite = Sprite2D.new()
		var tween = Game.tree.create_tween()
		tween.tween_callback(func():
			Game.sfx_monster_death.play()
			blood_sprite.texture = load("res://fx/bloodsplats_0004.png")
			blood_sprite.scale = Vector2(0.6, 0.6)
			blood_sprite.position = pos
			Game.scene_root.add_child(blood_sprite)
			queue_free()
			var tile = Game.map[coord]
			if is_enemy:
				tile.monsters.erase(self)
			else:
				tile.player_units.erase(self)
			for m in tile.monsters:
				m.update_pos()
			for u in tile.player_units:
				u.update_pos()
				
		)
		tween.tween_interval(0.3)
		tween.tween_callback(func():
			blood_sprite.queue_free()
		)

func move_to(_coord : Vector2i):
	var tile = Game.map[coord]
	if is_enemy:
		tile.monsters.erase(self)
	else:
		tile.player_units.erase(self)
	coord = _coord
	var new_tile = Game.map[coord]
	if is_enemy:
		new_tile.monsters.append(self)
	else:
		new_tile.player_units.append(self)
	for m in tile.monsters:
		m.update_pos()
	for u in tile.player_units:
		u.update_pos()
	for m in new_tile.monsters:
		m.update_pos()
	for u in new_tile.player_units:
		u.update_pos()

func setup(key : String, _coord : Vector2i):
	var info = get_info(key)
	unit_name = key
	display_name = info.display_name
	description = info.description
	icon = info.icon
	atk = info.atk
	max_hp = info.max_hp
	hp = max_hp
	
	coord = _coord
	position = Game.tilemap.to_global(Game.tilemap.map_to_local(coord))
	scale = Vector2(0.5, 0.5)

func _ready() -> void:
	sprite.texture = load(icon)
	for n in health_bar.get_children():
		health_bar.remove_child(n)
		n.queue_free()
	var n_seg = max(1, max_hp / 4)
	for i in n_seg:
		var seg = TextureRect.new()
		seg.texture = load("res://ui/health_bar_seg.png")
		var bar = TextureRect.new()
		bar.texture = load("res://ui/health_bar1.png")
		bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		seg.add_child(bar)
		health_bar.add_child(seg)
	update_hp()
	
	var tween = Game.tree.create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
