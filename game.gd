extends Node2D

class_name Game

enum
{
	SelectCaveState,
	MineState,
	ShoppingState,
	ResultState
}

enum
{
	NoneResource,
	ProductionResource,
	GoldResource,
	ScienceResource,
	FoodResource,
	GearResource
}

const card_width = 120
const card_height = 144
const card_hf_width = card_width / 2
const card_hf_height = card_height / 2
const tile_sz = 72

static var cx = 0
static var cy = 0

static var map : Dictionary[Vector2i, Tile]
static var player : Player
static var techs : Dictionary
static var turn : int = 0
static var state : int = SelectCaveState
static var gameover : bool = false
static var cave : Cave = null
static var cave_candidates : Array[Cave]
static var busy : bool = false

static var last_hovered = Vector2i(-1, -1)
static var hovering_tile = Vector2i(-1, -1)

const Camera = preload("res://camera.gd")
const TilemapOverlay = preload("res://tilemap_overlay.gd")
const CardPrefab = preload("res://card.tscn")
const UnitPrefab = preload("res://unit.tscn")
const OrePrefab = preload("res://ore.tscn")
const ShopItemPrefab = preload("res://shop_item.tscn")
const TechItemPrefab = preload("res://tech_item.tscn")
const explosion_frames = preload("res://fx/explosion.tres")

@onready var camera = $Scene/Camera2D
@onready var root = $"."
@onready var turn_tip = $UI/HBoxContainer/VBoxContainer/Panel/TurnTip
@onready var turn_text = $UI/HBoxContainer/VBoxContainer/Panel/TurnTip/MarginContainer/Label
@onready var left_panel = $UI/HBoxContainer/Panel
@onready var bottom_panel = $UI/HBoxContainer/VBoxContainer/Panel2
@onready var alert_panel = $UI/HBoxContainer/VBoxContainer/Panel/Alert
@onready var alert_text = $UI/HBoxContainer/VBoxContainer/Panel/Alert/Panel/MarginContainer/Label
@onready var resource_panel = $UI/HBoxContainer/Panel/VBoxContainer/ResourcePanel
@onready var production_text = $UI/HBoxContainer/Panel/VBoxContainer/ResourcePanel/HBoxContainer/Production
@onready var gold_text = $UI/HBoxContainer/Panel/VBoxContainer/ResourcePanel/HBoxContainer2/Gold
@onready var science_text = $UI/HBoxContainer/Panel/VBoxContainer/ResourcePanel/HBoxContainer3/Science
@onready var food_text = $UI/HBoxContainer/Panel/VBoxContainer/ResourcePanel/HBoxContainer4/Food
@onready var energy_text = $UI/HBoxContainer/VBoxContainer/Panel/Mine/EnergyText
@onready var state_text = $UI/HBoxContainer/Panel/VBoxContainer/State
@onready var collapse_turn_text = $UI/HBoxContainer/Panel/VBoxContainer/CollapseTurn
@onready var target_score_text = $UI/HBoxContainer/Panel/VBoxContainer/TargetScore
@onready var cave_select_ui = $UI/HBoxContainer/VBoxContainer/Panel/CaveSelect
@onready var cave_candidate1_ui = $UI/HBoxContainer/VBoxContainer/Panel/CaveSelect/HBoxContainer/CaveCandidate1
@onready var cave_candidate2_ui = $UI/HBoxContainer/VBoxContainer/Panel/CaveSelect/HBoxContainer/CaveCandidate2
@onready var cave_candidate3_ui = $UI/HBoxContainer/VBoxContainer/Panel/CaveSelect/HBoxContainer/CaveCandidate3
@onready var mine_ui = $UI/HBoxContainer/VBoxContainer/Panel/Mine
@onready var scene_view = $UI/HBoxContainer/VBoxContainer/Panel/Mine/SceneView
@onready var power_text = $UI/HBoxContainer/VBoxContainer/Panel/Mine/PowerText
@onready var camera_left_button = $UI/HBoxContainer/VBoxContainer/Panel/Mine/CameraLeftButton
@onready var camera_up_button = $UI/HBoxContainer/VBoxContainer/Panel/Mine/CameraUpButton
@onready var camera_right_button = $UI/HBoxContainer/VBoxContainer/Panel/Mine/CameraRightButton
@onready var camera_down_button = $UI/HBoxContainer/VBoxContainer/Panel/Mine/CameraDownButton
@onready var end_turn_button = $UI/HBoxContainer/VBoxContainer/Panel/Mine/EndTurn
@onready var gradient_frame = $UI/HBoxContainer/VBoxContainer/Panel/Mine/TextureRect
@onready var shop_ui = $UI/HBoxContainer/VBoxContainer/Panel/Shop
@onready var shop_list = $UI/HBoxContainer/VBoxContainer/Panel/Shop/VBoxContainer/MarginContainer/GridContainer
@onready var result_ui = $UI/HBoxContainer/VBoxContainer/Panel/Result
@onready var result_title = $UI/HBoxContainer/VBoxContainer/Panel/Result/VBoxContainer/Label
@onready var result_text = $UI/HBoxContainer/VBoxContainer/Panel/Result/VBoxContainer/Label2
@onready var result_button = $UI/HBoxContainer/VBoxContainer/Panel/Result/VBoxContainer/Button
@onready var hand = $UI/HBoxContainer/VBoxContainer/Panel2/Hand
@onready var deck = $UI/HBoxContainer/VBoxContainer/Panel2/Deck
@onready var tech_ui = $UI/TechTree
@onready var tech_tree = $UI/TechTree/VBoxContainer/ScrollContainer/Panel
@onready var tooltip = $UI/ToolTip
@onready var tooltip_text = $UI/ToolTip/VBoxContainer/Text
static var sfx_click : AudioStreamPlayer
static var sfx_hover : AudioStreamPlayer
static var sfx_open : AudioStreamPlayer
static var sfx_close : AudioStreamPlayer
static var sfx_error : AudioStreamPlayer
static var sfx_draw : AudioStreamPlayer
static var sfx_buy : AudioStreamPlayer
static var sfx_build : AudioStreamPlayer
static var sfx_shuffle : AudioStreamPlayer
static var sfx_sword : AudioStreamPlayer
static var sfx_monster_move : AudioStreamPlayer
static var sfx_monster_death : AudioStreamPlayer
static var sfx_pickaxe : AudioStreamPlayer
static var sfx_rocket_loop : AudioStreamPlayer
static var sfx_explosion : AudioStreamPlayer

static var tree : SceneTree = null
static var scene_root : SubViewport = null
static var tilemap_water : TileMapLayer = null
static var tilemap_bank : TileMapLayer = null
static var tilemap : TileMapLayer = null
static var tilemap_convex : TileMapLayer = null
static var tilemap_floor2 : TileMapLayer = null
static var tilemap_convex2 : TileMapLayer = null
static var tilemap_object : TileMapLayer = null
static var tilemap_overlay : Node2D = null
static var ui_root : CanvasLayer = null
const scene_off = Vector2(208, 7)

var turn_tip_tween : Tween = null
var production_text_tween : Tween = null
var gold_text_tween : Tween = null
var science_text_tween : Tween = null
var food_text_tween : Tween = null
var dragging_card : Card = null
var drag_offset : Vector2
var can_activate = false
var tooltip_using = false

var select_tile_callback : Callable

static func SmoothDamp(current : float, target : float, currentVelocity : Dictionary, smoothTime : float, maxSpeed : float , deltaTime : float)->float:
	smoothTime = max(0.0001, smoothTime)
	var num = 2 / smoothTime
	var num2 = num * deltaTime
	var num3 = 1 / (1 + num2 + 0.48 * num2 * num2 + 0.235 * num2 * num2 * num2)
	var num4 = current - target
	var num5 = target
	var num6 = maxSpeed * smoothTime
	num4 = clamp (num4, -num6, num6)
	target = current - num4
	var num7 = (currentVelocity.v + num * num4) * deltaTime
	currentVelocity.v = (currentVelocity.v - num * num7) * num3
	var num8 = target + (num4 + num7) * num3
	if num5 - current > 0 == num8 > num5:
		num8 = num5
		currentVelocity.v = (num8 - num5) / deltaTime
	return num8

static func get_shuffled_indices(n : int):
	var ret = []
	for i in n:
		ret.append(i)
	ret.shuffle()
	return ret

static func get_resource_name(type : int):
	if type == ProductionResource:
		return "production"
	if type == GoldResource:
		return "gold"
	if type == ScienceResource:
		return "science"
	if type == FoodResource:
		return "food"

static func get_resource_icon(type : int):
	if type == ProductionResource:
		return "res://icons/production.png"
	if type == GoldResource:
		return "res://icons/gold.png"
	if type == ScienceResource:
		return "res://icons/science.png"
	if type == FoodResource:
		return "res://icons/food.png"

static func get_surrounding_tiles(tile : Tile) -> Array[Tile] :
	var ret : Array[Tile] = []
	if tile.tile_b.x != -1:
		ret.append(map[tile.tile_b])
	if tile.tile_lb.x != -1:
		ret.append(map[tile.tile_lb])
	if tile.tile_lt.x != -1:
		ret.append(map[tile.tile_lt])
	if tile.tile_rb.x != -1:	
		ret.append(map[tile.tile_rb])
	if tile.tile_rt.x != -1:
		ret.append(map[tile.tile_rt])
	if tile.tile_t.x != -1:
		ret.append(map[tile.tile_t])
	return ret

static func is_tile_reachable(tile : Tile):
	for t in get_surrounding_tiles(tile):
		if t.terrain != Tile.TerrainFloor2:
			return true
	return false

static func get_surrounding_tiles_within(tile : Tile, range : int) -> Array:
	var ret = []
	if range <= 0:
		return ret
	var start = 0
	var end = 1
	ret.append(tile)
	while range > 0:
		for i in range(start, end):
			var t = ret[i]
			for _t in get_surrounding_tiles(t):
				if !ret.has(_t):
					ret.append(_t)
		start = end
		end = ret.size()
		range -= 1
	return ret
	
static func find_path_on_map(start : Vector2i, end : Vector2i) -> Array[Tile]:
	var ret : Array[Tile] = []
	var start_tile = map[start] as Tile
	if !start_tile.passable:
		return []
	if start.x == end.x && start.y == end.y:
		ret.append(start_tile)
		return ret
	var end_tile = map[end] as Tile
	if !end_tile.passable:
		return []
	var scaned = {}
	scaned[start] = { "d": 0, "read": false }
	var max_d = max(cx, cy)
	var found = false
	for c in scaned:
		if !scaned[c].read:
			for t in get_surrounding_tiles(map[c]):
				if !t.passable:
					continue
				if !scaned.has(t.coord):
					var d = scaned[c].d + 1
					if d > max_d:
						return []
					scaned[t.coord] = { "d": d, "read": false }
				if t == end_tile:
					found = true
					break
			scaned[c].read = true
		if found:
			break
	if !found:
		return []
	ret.append(end_tile)
	found = false
	var reverse_loop = false
	while true:
		var t = ret[0]
		var _d = scaned[t.coord].d
		var surroundings = get_surrounding_tiles(t)
		var _range
		if reverse_loop:
			_range = range(surroundings.size() - 1, -1, -1)
			reverse_loop = false
		else:
			_range = range(0, surroundings.size(), 1)
			reverse_loop = true
		for i in _range:
			var _t = surroundings[i]
			if _t == start_tile:
				found = true
				break
			if scaned.has(_t.coord) && scaned[_t.coord].d == _d - 1:
				ret.push_front(_t)
				break
		if found:
			break
	ret.push_front(start_tile)
	return ret

var alert_tween : Tween = null
func alert(text: String):
	if alert_tween != null:
		alert_tween.kill()
		alert_tween = null
	alert_panel.show()
	alert_panel.add_theme_constant_override("margin_top", 50)
	alert_text.text = text
	alert_tween = tree.create_tween()
	alert_tween.tween_method(func(v : int):
		alert_panel.add_theme_constant_override("margin_top", v)
	, 50, 45, 0.15)
	alert_tween.tween_interval(0.8)
	alert_tween.tween_callback(func():
		alert_panel.hide()
		alert_tween = null
	)

func yes_no_dialog(text : String, callback : Callable):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	dialog.ok_button_text = "Yes"
	dialog.add_cancel_button("No")
	dialog.confirmed.connect(func():
		callback.call(true)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		callback.call(false)
		dialog.queue_free()
	)
	ui_root.add_child(dialog)
	dialog.popup_centered()
		
static func add_resource(type : int, v : int, pos : Vector2, parent_node : Node = ui_root):
	if type == ProductionResource:
		player.add_production(v)
	elif type == GoldResource:
		player.add_gold(v)
	elif type == ScienceResource:
		player.add_science(v)
	elif type == FoodResource:
		player.add_food(v)
			
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var text : String
	if v > 0:
		text = "[color=green]+%d[/color]" % v
	else:
		text = "[color=red]%d[/color]" % v
	if type == ProductionResource:
		text += "[img=20]res://icons/production.png[/img]"
	elif type == GoldResource:
		text += "[img=20]res://icons/gold.png[/img]"
	elif type == ScienceResource:
		text += "[img=20]res://icons/science.png[/img]"
	elif type == FoodResource:
		text += "[img=20]res://icons/food.png[/img]"
	label.text = text
	label.position = Vector2(0, -100)
	parent_node.add_child(label)
	var tween = tree.create_tween()
	tween.tween_method(func(v : int):
		label.position = pos - Vector2(label.size.x * 0.5, v)
	, 0, 15, 0.3)
	tween.tween_callback(func():
		label.queue_free()
	)

func update_gold_text(o, n):
	if gold_text_tween:
		gold_text_tween.kill()
	gold_text_tween = tree.create_tween()
	gold_text_tween.tween_method(func(v):
			gold_text.text = "%d" % v,
		o, n, 0.5
	)
	gold_text_tween.tween_callback(func():
		gold_text_tween = null
	)
	
	if shop_ui.visible:
		update_shop_list()

func update_energy_text():
	energy_text.text = "%d/%d" % [player.energy, player.max_energy]

func update_turn_text():
	collapse_turn_text.text = "倒塌回合：%d/%d" % [turn, cave.collapse_turn]

func update_ruby_value_text():
	pass

func create_card() -> Card:
	var card = CardPrefab.instantiate()
	card.mouse_entered.connect(func():
		tooltip_using = true
		var text = card.display_name
		text += "\n%s" % card.description
		tooltip_text.text = text
		tooltip.show()
		sfx_hover.play()
	)
	card.mouse_exited.connect(func():
		tooltip_using = true
		tooltip.hide()
	)
	card.clicked.connect(func():
		if dragging_card != null:
			release_dragging_card()
			return
		dragging_card = card
		if dragging_card.target_type == Card.TargetNull:
			gradient_frame.modulate = Color(1.0, 1.0, 1.0, 0.15)
			gradient_frame.show()
		
		sfx_draw.play()
	)
	return card

func fly_card_to_hand(card : Card, pos : Vector2):
	ui_root.add_child(card)
	card.position = pos
	card.scale = Vector2(0.2, 0.2)
	var tween = tree.create_tween()
	tween.tween_property(card, "position", hand.global_position + Vector2(min(hand.hand_width, hand.get_child_count() * (card_width + hand.gap0)), 0), 0.15)
	tween.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_callback(func():
		card.reparent(hand)
	)

func draw_card(card : Card):
	ui_root.add_child(card)
	var p0 = deck.rect.global_position + Vector2(-30, -60)
	var p1 = hand.global_position + hand.get_card_pos(-1)
	card.position = p0
	card.scale = Vector2(0.5, 0.5)
	card.lock = true
	card.back_face()
	var tween = tree.create_tween()
	tween.tween_property(card, "position", (p0 + p1) * 0.5, 0.15)
	tween.parallel().tween_property(card, "scale", Vector2(0.75, 0.75), 0.15)
	tween.parallel().tween_method(func(t : float):
		card.xy_quat = Quaternion(Vector3(0.0, 1.0, 0.0), deg_to_rad(t))
		card.update_rotation()
	, -180, -90, 0.15)
	tween.tween_callback(func():
		card.front_face()
	)
	tween.tween_property(card, "position", p1, 0.15)
	tween.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.15)
	tween.parallel().tween_method(func(t : float):
		card.xy_quat = Quaternion(Vector3(0.0, 1.0, 0.0), deg_to_rad(t))
		card.update_rotation()
	, -90, 0, 0.15)
	tween.tween_callback(func():
		card.xy_quat = Quaternion(0.0, 0.0, 0.0, 1.0)
	)
	tween.tween_callback(func():
		card.lock = false
		card.reparent(hand)
	)

func discard_card(card : Card):
	card.reparent(ui_root)
	card.lock = true
	var p0 = deck.rect.global_position + Vector2(-30, +20)
	var p1 = hand.global_position + hand.get_card_pos(0)
	var tween = tree.create_tween()
	tween.tween_property(card, "position", (p0 + p1) * 0.5, 0.15)
	tween.parallel().tween_property(card, "scale", Vector2(0.75, 0.75), 0.15)
	tween.parallel().tween_method(func(t : float):
		card.xy_quat = Quaternion(Vector3(0.0, 1.0, 0.0), deg_to_rad(t))
		card.update_rotation()
	, 0, -90, 0.15)
	tween.tween_callback(func():
		card.back_face()
	)
	tween.tween_property(card, "position", p0, 0.15)
	tween.parallel().tween_property(card, "scale", Vector2(0.5, 0.5), 0.15)
	tween.parallel().tween_method(func(t : float):
		card.xy_quat = Quaternion(Vector3(0.0, 1.0, 0.0), deg_to_rad(t))
		card.update_rotation()
	, -90, -180, 0.15)
	tween.tween_callback(func():
		card.lock = false
		ui_root.remove_child(card)
		deck.discard_pile.append(card)
	)

static func add_unit(name : String, coord : Vector2i, is_enemy : bool):
	var unit = UnitPrefab.instantiate()
	unit.setup(name, coord)
	var tile = map[coord]
	if is_enemy:
		unit.is_enemy = true
		tile.monsters.append(unit)
		for m in tile.monsters:
			m.update_pos()
	else:
		unit.is_enemy = false
		tile.player_units.append(unit)
		for u in tile.player_units:
			u.update_pos()
	scene_root.add_child(unit)
	return unit

static func add_ore(tile : Tile, type : int):
	if !tile.ore:
		var ore : Ore = OrePrefab.instantiate()
		ore.setup(type, tile.coord)
		tile.ore = ore
		scene_root.add_child(ore)
		return ore
	return null

static func reveal(tile : Tile, range : int = 1):
	if tile.terrain == Tile.TerrainFloor2:
		if tile.coord != player.coord:
			if randf() > 0.3:
				add_ore(tile, randi_range(Ore.GoldOre, Ore.AmethystOre))
		tile.terrain = Tile.TerrainFloor
		tile.passable = true
	if range > 0:
		for t in get_surrounding_tiles(tile):
			reveal(t, range - 1)

static func dig(tile : Tile, damage : int = 4, use_animation = true):
	if tile.mineral_fragile:
		damage *= 2
	var prev_hp = tile.mineral_hp
	tile.mineral_hp = max(0, tile.mineral_hp - damage)
	var minerals = (prev_hp - tile.mineral_hp) / 4
	
	var gold = 0
	if tile.ore:
		if tile.ore.type == Ore.GoldOre:
			gold = 100 * minerals
		elif tile.ore.type == Ore.RubyOre:
			gold = 100 * minerals
		elif tile.ore.type == Ore.EmeraldOre:
			gold = 100 * minerals
		elif tile.ore.type == Ore.SapphireOre:
			gold = 100 * minerals
		elif tile.ore.type == Ore.AmethystOre:
			gold = 100 * minerals
	reveal(tile)
	
	var pos = tilemap.to_global(tilemap.map_to_local(tile.coord))
	if use_animation:
		var tween = tree.create_tween()
		var crack_sprite = Sprite2D.new()
		tween.tween_callback(func():
			sfx_pickaxe.play(0.33)
			crack_sprite.texture = load("res://fx/crack.png")
			crack_sprite.position = pos
			Game.scene_root.add_child(crack_sprite)
			
			reveal(tile)
			update_tiles()
		)
		tween.tween_interval(0.5)
		tween.parallel().tween_callback(func():
			add_resource(GoldResource, gold, pos - Vector2(0, 20), scene_root)
		)
		tween.parallel().tween_property(crack_sprite, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(func():
			crack_sprite.queue_free()
		)
	else:
		add_resource(GoldResource, gold, pos - Vector2(0, 20), scene_root)

static func attack(tile : Tile, damage : int = 4, use_animation = true):
	var _monsters = tile.monsters
	if use_animation:
		var slash_sprite = Sprite2D.new()
		var pos = tilemap.to_global(tilemap.map_to_local(tile.coord))
		var tween = tree.create_tween()
		tween.tween_callback(func():
			sfx_sword.play()
			slash_sprite.texture = load("res://fx/slash.png")
			slash_sprite.scale = Vector2(0.8, 0.8)
			slash_sprite.position = pos
			Game.scene_root.add_child(slash_sprite)
			
			for m in _monsters:
				m.take_damage(damage)
		)
		tween.tween_interval(0.5)
		tween.tween_callback(func():
			slash_sprite.queue_free()
		)
	else:
		for m in _monsters:
			m.take_damage(damage)

func new_turn():
	turn += 1
	player.calc_max_energy()
	player.restore_energy()
	
	turn_tip.modulate.a = 1
	turn_tip.show()
	turn_text.text = "回合%d" % turn
	if turn_tip_tween != null:
		turn_tip_tween.kill()
		turn_tip_tween = null
	turn_tip_tween = tree.create_tween()
	turn_tip_tween.tween_interval(0.5)
	turn_tip_tween.tween_property(turn_tip, "modulate:a", 0, 0.3)
	turn_tip_tween.tween_callback(func():
		turn_tip.hide()
		turn_tip_tween = null
	)
	
	update_turn_text()
	
	shop_ui.hide()
	tech_ui.hide()
	
	var tween = tree.create_tween()
	tween.tween_interval(0.5)
	
	if hand.get_child_count():
		tween.tween_callback(func():
			sfx_shuffle.play()
		)
		for c in hand.get_children():
			tween.tween_callback(func():
				discard_card(c)
			)
			tween.tween_interval(0.1)
	
	tween.tween_interval(0.5)
	var enemies : Array[Tile]
	var ores : Array[Tile]
	for c in map:
		var tile = map[c]
		if !tile.monsters.is_empty():
			enemies.append(tile)
		if tile.ore:
			ores.append(tile)
	for c in map:
		var tile = map[c]
		for u in tile.player_units:
			var shortest_path : Array[Tile] = []
			for t in enemies:
				var path = find_path_on_map(u.coord, t.coord)
				if !path.is_empty() && (shortest_path.is_empty() || path.size() < shortest_path.size()):
					shortest_path = path
			if shortest_path.is_empty():
				for t in ores:
					var path = find_path_on_map(u.coord, t.coord)
					if !path.is_empty() && (shortest_path.is_empty() || path.size() < shortest_path.size()):
						shortest_path = path
			if shortest_path.size() > 1:
				tween.tween_callback(func():
					u.move_to(shortest_path[1].coord)
					u.update_pos()
					sfx_monster_move.play()
				)
				tween.tween_interval(0.25)
		for m in tile.monsters:
			var path = find_path_on_map(m.coord, player.coord)
			if path.size() > 1:
				tween.tween_callback(func():
					m.move_to(path[1].coord)
					m.update_pos()
					sfx_monster_move.play()
				)
				tween.tween_interval(0.25)
	
	await tween.finished
	
	for c in map:
		var tile = map[c]
		var monsters = []
		var units = []
		for m in tile.monsters:
			monsters.append(m)
		for u in tile.player_units:
			units.append(u)
		while !monsters.is_empty() && !units.is_empty():
			var m = monsters.pick_random()
			var u = units.pick_random()
			m.take_damage(u.atk)
			if m.hp <= 0:
				monsters.erase(m)
			if !monsters.is_empty():
				var m2 = monsters.pick_random()
				var u2 = units.pick_random()
				u2.take_damage(m2.atk)
				if u2.hp <= 0:
					units.erase(u2)
		if !monsters.is_empty():
			player.remove_building(tile.coord)
	
	if !player.buildings.has(player.coord):
		change_state(ResultState, { "gameover": true })
		
	if state != ResultState:
		var tween2 = tree.create_tween()
		for c in player.buildings:
			var building = player.buildings[c]
			var tile = map[c]
			
			var pos = tilemap.to_global(tilemap.map_to_local(c))
			tween2.tween_interval(0.15)
			tween2.tween_callback(func():
				camera.move_to(pos)
			)
			tween2.tween_interval(0.2)
			
			if building.effect.has("type"):
				var type = building.effect["type"]
				if type == "":
					pass
				elif type == "auto_digging":
					tween2.tween_callback(func():
						dig(tile)
					)
			if building.effect.has("production"):
				var production = building.ext["production"]
				if production > 0:
					tween2.tween_callback(func():
						add_resource(ProductionResource, production, pos, scene_root)
					)
			if building.effect.has("train_unit_name"):
				var unit_name = building.effect["train_unit_name"]
				var unit_count = building.effect["train_unit_count"]
				var unit_info = Unit.get_info(unit_name)
				var num = min(player.food / unit_info.cost_food, unit_count)
				if num > 0:
					player.add_food(-(num * unit_info.cost_food))
					
					tween2.tween_callback(func():
						sfx_shuffle.play()
					)
					for i in num:
						tween2.tween_callback(func():
							var card = create_card()
							card.setup_unit_card(unit_name)
							fly_card_to_hand(card, tilemap.get_canvas_transform().origin + pos - Vector2(card_hf_width, card_hf_height))
							add_unit(unit_name, c, false)
						)
						tween2.tween_interval(0.1)
						
					unit_count -= num
		
		tween2.tween_callback(func():
			sfx_shuffle.play()
		)
		for i in 5:
			tween2.tween_callback(func():
				var card = deck.draw()
				if card:
					draw_card(card)
			)
			tween2.tween_interval(0.1)

func change_state(new_state : int, data : Dictionary) :
	state = new_state
	if state == SelectCaveState:
		state_text.text = "[wave amp=50.0 freq=3.0 connected=1]选择一个矿洞[/wave]"
		var cand1 = Cave.new()
		cand1.name = "普通的矿洞"
		cand1.target_score = 300
		cand1.collapse_turn = 3
		cave_candidates.append(cand1)
		var cand2 = Cave.new()
		cand2.name = "困难的矿洞"
		cand2.target_score = 400
		cand2.collapse_turn = 3
		cave_candidates.append(cand2)
		var cand3 = Cave.new()
		cand3.name = "残酷的矿洞"
		cand3.target_score = 600
		cand3.collapse_turn = 3
		cave_candidates.append(cand3)
		var update_cand_ui = func(ui : Control, cand : Cave):
			ui.find_child("Name").text = cand.name
			ui.find_child("TargetScore").text = "目标：%d" % cand.target_score
		update_cand_ui.call(cave_candidate1_ui, cand1)
		update_cand_ui.call(cave_candidate2_ui, cand2)
		update_cand_ui.call(cave_candidate3_ui, cand3)
		cave_select_ui.show()
	elif state == MineState:
		cave = cave_candidates[data.select]
		cave_candidates.clear()
		
		turn = 0
		
		cx = cave.cx
		cy = cave.cy
		
		map.clear()
		for x in cx:
			for y in cy:
				var coord = Vector2i(x, y)
				var terrain = Tile.TerrainFloor2
				var t = Tile.new(coord, terrain)
				map[coord] = t
		for c in map:
			map[c].init_surroundings(map)

		player.coord = Vector2i(cx / 2, cy / 2)
		player.add_building(player.coord, "drilling_tank")
		reveal(map[player.coord], 1)
		
		update_tiles()
		
		add_unit("monster", Vector2i(8, 10), true)
		
		camera.position = tilemap.map_to_local(tilemap.get_used_rect().get_center())
		
		tilemap_overlay.update_border()
		
		player.gold_changed.connect(update_gold_text)
		player.energy_changed.connect(update_energy_text)
		update_gold_text(0, player.gold)
	
		state_text.text = cave.name
		collapse_turn_text.show()
		target_score_text.text = "目标：%d" % cave.target_score
		target_score_text.show()
		cave_select_ui.hide()
		mine_ui.show()
		hand.show()
	
		new_turn()
	elif state == ShoppingState:
		update_shop_list()
		
		result_ui.hide()
		shop_ui.show()
	elif state == ResultState:
		gameover = data["gameover"]
		if gameover:
			result_title.text = "游戏结束"
			result_text.text = "未能逃离矿洞"
			result_button.text = "重试"
		else:
			result_title.text = "已逃离"
			var text = ""
			result_text.text = text
			result_button.text = "继续"
		
		tooltip.hide()
		mine_ui.hide()
		hand.hide()
		result_ui.show()

func save_game(path : String):
	var saving = {
		"turn": turn,
		"state": state,
		"cx": cx,
		"cy": cy
	}
	var _map = {}
	for c in map:
		var tile = map[c] as Tile
		var _units = tile.get_neutral_unit_types()
		var t = {
			"terrain": tile.terrain,
			"resource_type": tile.resource_type,
			"resource_amount": tile.resource_amount,
			"units": _units
		}
		_map[c] = t
	saving["map"] = _map
	var _buildings = {}
	for c in player.buildings:
		var building = player.buildings[c] as Building
		var b = {
			"name": building.building_name,
			"display_name": building.display_name,
			"description": building.description,
			"ext": building.ext
		}
		_buildings[c] = b
	var _units = []
	for u in player.units:
		_units.append(u.unit_name)
	var _player = {
		"coord": player.coord,
		"buildings": _buildings,
		"vision": player.vision,
		"production": player.production,
		"gold": player.gold,
		"science": player.science,
		"food": player.food,
		"gear": player.gear,
		"units": _units
	}
	var _hand = []
	saving["player"] = _player
	saving["hand"] = []
	var json = JSON.stringify(saving, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json)
	file.close()

func load_game(path : String):
	var json = FileAccess.get_file_as_string(path)
	json = JSON.parse_string(json)
	
	turn = json["turn"]
	state = json["state"]
	cx = json["cx"]
	cy = json["cy"]

	map.clear()
	var _map = json["map"] as Dictionary
	for c in _map:
		var t = _map[c]
		var tile = Tile.new(str_to_var("Vector2i" + c), t["terrain"])
		tile.resource_type = t["resource_type"]
		tile.resource_amount = t["resource_amount"]
		map[tile.coord] = tile
	for c in map:
		map[c].init_surroundings(map)
	
	var _player = json["player"] as Dictionary
	var _buildings = _player["buildings"]
	var _units = _player["units"]
	player.coord = str_to_var("Vector2i" + _player["coord"])
	player.production = _player["production"]
	player.gold = _player["gold"]
	player.science = _player["science"]
	player.food = _player["food"]
	player.gear = _player["gear"]
	for c in _buildings:
		var b = _buildings[c]
		var building = player.add_building(b["name"], str_to_var("Vector2i" + c))
	for u in _units:
		var c = u["coord"]
		var unit = add_unit(u["name"], str_to_var("Vector2i" + c), false)
	
	techs.clear()
	
	var _hand = json["hand"]
	for c in _hand:
		if c.type == Card.NormalCard:
			pass
		#elif c.type == Card.TerritoryCard:
		#	var card = create_card()
		#	card.setup("territory")
		#	hand.add_child(card)
		elif c.type == Card.BuildingCard:
			var card = create_card()
			card.setup_building_card(c.name.substr(0, c.name.length() - 9))
			hand.add_child(card)
			pass
		elif c.type == Card.UnitCard:
			var card = create_card()
			card.setup_unit_card(c.name.substr(0, c.name.length() - 5))
			hand.add_child(card)

func on_select_cave1() -> void:
	sfx_click.play()
	change_state(MineState, { "select": 0 })

func on_select_cave2() -> void:
	sfx_click.play()
	change_state(MineState, { "select": 1 })

func on_select_cave3() -> void:
	sfx_click.play()
	change_state(MineState, { "select": 2 })

func add_shop_item(card_type : int, name : String, use_resource : int, cost : int, amount : int):
	var shop_item = ShopItemPrefab.instantiate()
	#if card_type == Card.TerritoryCard:
	#	shop_item.card.setup("territory")
	#	shop_item.setup(use_resource, cost)
	if card_type == Card.NormalCard:
		shop_item.find_child("Card").setup(name)
		shop_item.setup(use_resource, cost)
	elif card_type == Card.BuildingCard:
		var info = Building.get_info(name)
		shop_item.card.setup_building_card(name)
		shop_item.setup(use_resource, info.cost_gold)
	elif card_type == Card.UnitCard:
		var info = Unit.get_info(name)
		shop_item.card.setup_unit_card(name)
		shop_item.setup(GoldResource, info.cost_gold, amount)
	shop_item.mouse_entered.connect(func():
		tooltip_using = true
		var text = shop_item.card.display_name
		text += "\n%s" % shop_item.card.description.format(shop_item.card)
		tooltip_text.text = text
		tooltip.show()
		#sfx_hover.play()
	)
	shop_item.mouse_exited.connect(func():
		tooltip_using = true
		tooltip.hide()
	)
	shop_item.clicked.connect(func():
		if !tree.get_processed_tweens().is_empty():
			return
		var result = {}
		if shop_item.buy(result):
			add_resource(result.cost_type, -result.cost, shop_item.global_position)
			sfx_buy.play()
			if result.has("card_data"):
				var card = create_card()
				card.setup_from_data(inst_to_dict(shop_item.card))
				fly_card_to_hand(card, shop_item.global_position)
		else:
			alert(result.message)
			sfx_error.play()
	)
	shop_list.add_child(shop_item)

func update_shop_list():
	for n in shop_list.get_children():
		shop_list.remove_child(n)
		n.queue_free()
	add_shop_item(Card.NormalCard, "ruby_value_upgrade", GoldResource, 100, -1)
	add_shop_item(Card.NormalCard, "emerald_value_upgrade", GoldResource, 100, -1)
	add_shop_item(Card.NormalCard, "sapphire_value_upgrade", GoldResource, 100, -1)
	add_shop_item(Card.NormalCard, "amethyst_value_upgrade", GoldResource, 100, -1)
	#add_shop_item(Card.TerritoryCard, "", ProductionResource, 20 + (1) * 2, -1)

func update_tech_tree():
	for n in techs:
		var t = techs[n]
		var tech_item = TechItemPrefab.instantiate()
		tech_item.get_node("Label").text = "%d/%d" % [t.level, t.max_level]
		tech_item.position = t.coord
		tech_item.mouse_entered.connect(func():
			tooltip_using = true
			var info = Technology.get_info(n)
			var text = info.display_name
			text += "\n需要: %d点科技值" % info.cost_science
			var values = info.values.duplicate()
			for i in info.max_level:
				values["c%d" % (i + 1)] = "white" if i + 1 == t.level else "gray"
			text += "\n%s" % info.description.format(values)
			tooltip_text.text = text
			tooltip.show()
			
			#sfx_hover.play()
		)
		tech_item.mouse_exited.connect(func():
			tooltip_using = true
			tooltip.hide()
		)
		tech_item.clicked.connect(func():
			if player.science >= t.cost_science && t.level < t.max_level:
				add_resource(ScienceResource, -t.cost_science, tech_item.global_position)
				
				t.acquired(player)
				
				tech_item.get_node("Label").text = "%d/%d" % [t.level, t.max_level]
				tech_item.hide()
				tech_item.show()
		)
		tech_tree.add_child(tech_item)

func on_tech_close_button() -> void:
	tech_ui.hide()
	sfx_close.play()

func on_tech_button() -> void:
	if tech_ui.visible:
		tech_ui.hide()
		sfx_close.play()
	else:
		shop_ui.hide()
		tech_ui.show()
		sfx_open.play()

func on_camera_left() -> void:
	sfx_click.play()
	camera.move_to(camera.position + Vector2(-72, 0))

func on_camera_up() -> void:
	sfx_click.play()
	camera.move_to(camera.position + Vector2(0, -72))

func on_camera_right() -> void:
	sfx_click.play()
	camera.move_to(camera.position + Vector2(+72, 0))

func on_camera_down() -> void:
	sfx_click.play()
	camera.move_to(camera.position + Vector2(0, +72))

func on_end_turn() -> void:
	if tree.get_processed_tweens().is_empty():
		sfx_click.play()
		if turn + 1 > cave.collapse_turn:
			if player.gold >= cave.target_score:
				#player.add_gold(-cave.target_score)
				change_state(ResultState, { "gameover": false })
			else:
				change_state(ResultState, { "gameover": false })
		else:
			new_turn()

func on_deck_clicked() -> void:
	pass

func on_continue() -> void:
	if gameover:
		pass
	else:
		change_state(ShoppingState, {})

func on_game_menu() -> void:
	if tree.get_processed_tweens().is_empty():
		$UI/GameMenu.show()
		sfx_open.play()

func on_resume() -> void:
	$UI/GameMenu.hide()
	sfx_open.play()

func on_save_game() -> void:
	save_game("res://savings/auto_save.txt")

func on_load_game() -> void:
	load_game("res://savings/auto_save.txt")
	tree.reload_current_scene()

func on_back_to_title() -> void:
	tree.change_scene_to_file("res://title_screen.tscn")

func on_quit() -> void:
	tree.quit()

static var map_rng = RandomNumberGenerator.new()

static func update_tiles():
	var rng_state = map_rng.state
	var rns = []
	for y in cy:
		for x in cx:
			rns.append(map_rng.randi_range(7, 12))
	
	for x in range(-1, cx + 1):
		for y in range(-1, cy + 1):
			var coord = Vector2i(x, y)
			tilemap_water.set_cell(coord, -1)
			tilemap_bank.set_cell(coord, -1)
			tilemap.set_cell(coord, -1)
			tilemap_convex.set_cell(coord, -1)
			tilemap_floor2.set_cell(coord, -1)
			tilemap_convex2.set_cell(coord, -1)
			tilemap_object.set_cell(coord, -1)
	
	var floor_tiles = {}
	var floor2_tiles = {}
	var gold_ore_tiles = {}
	for c in map:
		var tile = map[c] as Tile
		if tile.terrain == Tile.TerrainFloor:
			floor_tiles[c] = 1
		elif tile.terrain == Tile.TerrainFloor2:
			floor2_tiles[c] = 1
	if !floor_tiles.is_empty():
		for c in floor_tiles:
			tilemap.set_cell(c, 0, Vector2i(rns[c.x * cx + c.y], 0))
		var convex_tiles = {}
		for c in floor_tiles:
			var t = map[c]
			for _t in get_surrounding_tiles(t):
				var k = _t.coord
				if !convex_tiles.has(k) && !floor_tiles.has(k):
					convex_tiles[k] = 1
		if !convex_tiles.is_empty():
			tilemap_convex.set_cells_terrain_connect(convex_tiles.keys(), 0, 0, false)
		tilemap_convex2.set_cells_terrain_connect(floor_tiles.keys(), 0, 0, false)
	if !floor2_tiles.is_empty():
		for c in floor2_tiles:
			tilemap_floor2.set_cell(c, 0, Vector2i(rns[c.x * cx + c.y], 0))
	
	map_rng.state = rng_state

func new_game():
	gameover = false
	
	player = Player.new(0)
	
	for n in hand.get_children():
		n.queue_free()
	for c in deck.draw_pile:
		c.queue_free()
	deck.draw_pile.clear()
	for c in deck.discard_pile:
		c.queue_free()
	deck.discard_pile.clear()
	#for i in 10:
	#	var card = create_card()
	#	card.setup("dig")
	#	deck.add_card(card)
	#for i in 5:
	#	var card = create_card()
	#	card.setup("attack")
	#	deck.add_card(card)
	#for i in 5:
	#	var card = create_card()
	#	card.setup_building_card("auto_digging_machine")
	#	deck.add_card(card)
	for i in 5:
		var card = create_card()
		card.setup("discharge")
		deck.add_card(card)
	deck.shuffle()
	
	change_state(SelectCaveState, {})

func _ready() -> void:
	seed(Time.get_ticks_msec())
	
	tree = get_tree()
	scene_root = $Scene
	tilemap_water = $Scene/TileMapLayerWater
	tilemap_bank = $Scene/TileMapLayerBank
	tilemap = $Scene/TileMapLayerMain
	tilemap_convex = $Scene/TileMapLayerConvex
	tilemap_floor2 = $Scene/TileMapLayerFloor2
	tilemap_convex2 = $Scene/TileMapLayerConvex2
	tilemap_object = $Scene/TileMapLayerObject
	tilemap_overlay = $Scene/TileMapOverlay
	ui_root = $UI
	
	sfx_click = $Sound/Click
	sfx_hover = $Sound/Hover
	sfx_error = $Sound/Error
	sfx_draw = $Sound/Draw
	sfx_buy = $Sound/Buy
	sfx_open = $Sound/Open
	sfx_close = $Sound/Close
	sfx_build = $Sound/Build
	sfx_shuffle = $Sound/Shuffle
	sfx_sword = $Sound/Sword
	sfx_monster_move = $Sound/MonsterMove
	sfx_monster_death = $Sound/MonsterDeath
	sfx_pickaxe = $Sound/Pickaxe
	sfx_rocket_loop = $Sound/RocketLoop
	sfx_explosion = $Sound/Explosion
	
	left_panel.gui_input.connect(ui_generic_input)
	bottom_panel.gui_input.connect(ui_generic_input)
	mine_ui.mouse_entered.connect(func():
		if dragging_card && dragging_card.target_type == Card.TargetNull:
			gradient_frame.modulate = Color(1.0, 1.0, 0.3, 0.3)
			can_activate = true
	)
	mine_ui.mouse_exited.connect(func():
		if dragging_card && dragging_card.target_type == Card.TargetNull:
			gradient_frame.modulate = Color(1.0, 1.0, 1.0, 0.15)
			can_activate = false
	)
	
	new_game()

func card_applied(card : Card, tween : Tween):
	card.lock = true
	card.shadow.hide()
	if card.tween_drag:
		card.tween_drag.kill()
		card.tween_drag = null
	tween.tween_method(func(v : float):
		card.update_dissolve(v)
	,1.0, 0.0, 0.2)

func process_card_drop():
	var card = dragging_card
	var tween : Tween = tree.create_tween()
	var card_used = false
	var error_message = ""
	if dragging_card.target_type == Card.TargetNull:
		if can_activate:
			if player.get_energy(1):
				card_applied(card, tween)
				card_used = true
				
				if card.effect.has("type"):
					var effect_type = card.effect["type"]
					if effect_type == "give_card":
						var card_name = card.effect["name"]
						var n = card.effect["amount"]
						for i in n:
							tween.tween_callback(func():
								var new_card = create_card()
								new_card.setup(card_name)
								hand.add_child(new_card)
							)
							tween.tween_interval(0.2)
			else:
				error_message = "能量不足"
	elif dragging_card.target_type == Card.TargetTile || dragging_card.target_type == Card.TargetBuilding:
		if hovering_tile.x != -1:
			var tile = map[hovering_tile]
			if is_tile_reachable(tile):
				var pos = tilemap.to_global(tilemap.map_to_local(tile.coord))
				if card.type == Card.NormalCard:
					if card.effect.has("type"):
						var effect_type = card.effect["type"]
						if effect_type == "dig":
							if player.get_energy(1):
								card_applied(card, tween)
								card_used = true
								
								tween.tween_callback(func():
									dig(tile, 4)
									attack(tile, 2, false)
								)
							else:
								error_message = "能量不足"
						elif effect_type == "attack":
							if player.get_energy(1):
								card_applied(card, tween)
								card_used = true
								
								tween.tween_callback(func():
									attack(tile, 4)
									dig(tile, 2, false)
								)
							else:
								error_message = "能量不足"
						elif effect_type == "rocket":
							if player.get_energy(1):
								card_applied(card, tween)
								card_used = true
								
								var player_pos = tilemap.to_global(tilemap.map_to_local(player.coord))
								var t = player_pos.distance_to(pos) / 300.0
								var rocket_sprite = Sprite2D.new()
								var explosion_sprite = AnimatedSprite2D.new()
								tween.tween_callback(func():
									rocket_sprite.texture = load("res://fx/rocket.png")
									rocket_sprite.scale = Vector2(0.5, 0.5)
									rocket_sprite.rotation = (pos - player_pos).angle() + PI * 0.5
									rocket_sprite.position = player_pos
									Game.scene_root.add_child(rocket_sprite)
									sfx_rocket_loop.play()
								)
								tween.tween_property(rocket_sprite, "position", pos, t)
								tween.tween_callback(func():
									explosion_sprite.sprite_frames = explosion_frames
									explosion_sprite.play("default")
									explosion_sprite.scale = Vector2(0.2, 0.2)
									explosion_sprite.position = pos
									Game.scene_root.add_child(explosion_sprite)
									rocket_sprite.queue_free()
									sfx_rocket_loop.stop()
									sfx_explosion.play()
								)
								tween.tween_interval(0.25)
								tween.tween_callback(func():
									explosion_sprite.queue_free()
									
									dig(tile, 4, false)
									attack(tile, 4, false)
								)
							else:
								error_message = "能量不足"
						elif effect_type == "summon":
							var unit_name = card.effect["name"]
							var num = card.effect["num"]
							if player.get_energy(1):
								card_applied(card, tween)
								card_used = true
								
								for i in num:
									tween.tween_interval(0.25)
									tween.tween_callback(func():
										var unit = add_unit(unit_name, tile.coord, false)
									)
							else:
								error_message = "能量不足"
						elif effect_type == "discharge":
							if player.get_energy(1):
								card_applied(card, tween)
								card_used = true
								
								var charged_tiles = {}
								var discharged_tiles = {}
								var newly_charge_tiles = {}
								newly_charge_tiles[tile] = 1
								while !newly_charge_tiles.is_empty():
									for t in newly_charge_tiles:
										tween.tween_callback(func():
											var induction_sprite = AnimatedSprite2D.new()
											induction_sprite.sprite_frames = load("res://fx/induction.tres")
											induction_sprite.modulate = Color(1.0, 1.0, 0.2, 1.0)
											induction_sprite.play("default")
											induction_sprite.position = tilemap.to_global(tilemap.map_to_local(t.coord))
											Game.scene_root.add_child(induction_sprite)
											var tween2 = tree.create_tween()
											tween2.tween_interval(0.35)
											tween2.tween_callback(func():
												induction_sprite.queue_free()
											)
										)
										charged_tiles[t] = newly_charge_tiles[t]
									newly_charge_tiles.clear()
									for t in charged_tiles:
										var charge = charged_tiles[t]
										if charge > 0:
											for tt in get_surrounding_tiles(t):
												if !discharged_tiles.has(tt):
													newly_charge_tiles[tt] = charge - 1
									charged_tiles.clear()
									tween.tween_interval(0.3)
							else:
								error_message = "能量不足"
				elif card.type == Card.BuildingCard:
					if !tile.building:
						var building_name = card.card_name.substr(0, card.card_name.length() - 9)
						var info = Building.get_info(building_name)
						if info.need_terrain.find(tile.terrain) != -1:
							if player.get_energy(1):
								if Game.player.add_building(tile.coord, building_name):
									card_applied(card, tween)
									card_used = true
									
									sfx_build.play()
							else:
								error_message = "能量不足"
						else:
							error_message = "不符合建筑要求的地块类型"
					else:
						error_message = "领地上已经有别的建筑"
			else:
				error_message = "够不到"
	
	if card_used:
		tween.tween_callback(func():
			card.lock = false
			card.shadow.show()
			card.update_dissolve(1.0)
			card.get_parent().remove_child(card)
			deck.discard_pile.append(card)
		)
	else:
		sfx_error.play()
		alert(error_message)
	return false

func release_dragging_card():
	if dragging_card == null:
		return
	gradient_frame.hide()
	dragging_card.release_drag()
	dragging_card = null

func set_hovering_tile(coord : Vector2i):
	if hovering_tile.x != coord.x || hovering_tile.y != coord.y:
		hovering_tile = coord
		
		tilemap_overlay.queue_redraw()
		
		if select_tile_callback.is_valid():
			select_tile_callback.call(coord, true)
			
		if !tooltip_using && state == MineState:
			if coord.x == -1 && coord.y == -1:
				tooltip.hide()
			else:
				var t = map[coord] as Tile
				var text = "%s" % Tile.get_terrain_text(t.terrain)
				if t.building:
					text += "\n------------------------"
					text += "\n%s" % t.building.display_name
					text += "\n%s" % t.building.description.format(t.building.effect)
				else:
					text += "\n建筑: 无"
				tooltip_text.text = text
				tooltip.show()
		tooltip_using = false

func ui_generic_input(event: InputEvent):
	if event is InputEventMouse:
		set_hovering_tile(Vector2i(-1, -1))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if select_tile_callback.is_valid():
					select_tile_callback.call(hovering_tile, false)
					select_tile_callback = Callable()
			else:
				if dragging_card:
					process_card_drop()
					release_dragging_card()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if select_tile_callback.is_valid():
					select_tile_callback.call(Vector2i(-1, -1), false)
					select_tile_callback = Callable()
	if event is InputEventMouse:
		var pos = tilemap.get_global_transform_with_canvas().origin
		pos = event.global_position - scene_off - pos
		var coord = tilemap.local_to_map(pos)
		if coord.x >= 0 && coord.x < cx && coord.y >= 0 && coord.y < cy:
			set_hovering_tile(coord)
			
			if coord.x != last_hovered.x || coord.y != last_hovered.y:
				#sfx_hover.play()
				pass
		else:
			set_hovering_tile(Vector2i(-1, -1))
		last_hovered = coord
	
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_H:
				camera.move_to(tilemap.to_global(tilemap.map_to_local(player.coord)))
			elif event.keycode == KEY_T:
				on_tech_button()
