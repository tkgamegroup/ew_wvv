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
	Gold,
	Ruby,
	Emerald,
	Sapphire,
	Amethyst
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
static var turn : int = 0
static var deep : int = 0
static var cave_index : int = -1
static var state : int = SelectCaveState
static var water_level : int = 0
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
const explosion_frames = preload("res://fx/explosion.tres")

@onready var camera = $Scene/Camera2D
@onready var root = $"."
@onready var info_ui = $UI/HBoxContainer/VBoxContainer/Panel/Info
@onready var info_text = $UI/HBoxContainer/VBoxContainer/Panel/Info/MarginContainer/Label
@onready var left_panel = $UI/HBoxContainer/Panel
@onready var bottom_panel = $UI/HBoxContainer/VBoxContainer/Panel2
@onready var alert_panel = $UI/HBoxContainer/VBoxContainer/Panel/Alert
@onready var alert_text = $UI/HBoxContainer/VBoxContainer/Panel/Alert/Panel/MarginContainer/Label
@onready var cave_select_ui = $UI/HBoxContainer/VBoxContainer/Panel/CaveSelect
@onready var cave_candidate1_ui = $UI/HBoxContainer/VBoxContainer/Panel/CaveSelect/HBoxContainer/CaveCandidate1
@onready var cave_candidate2_ui = $UI/HBoxContainer/VBoxContainer/Panel/CaveSelect/HBoxContainer/CaveCandidate2
@onready var cave_candidate3_ui = $UI/HBoxContainer/VBoxContainer/Panel/CaveSelect/HBoxContainer/CaveCandidate3
@onready var mine_ui = $UI/HBoxContainer/VBoxContainer/Panel/Mine
@onready var scene_view = $UI/HBoxContainer/VBoxContainer/Panel/Mine/SceneView
@onready var end_turn_timer = $UI/HBoxContainer/VBoxContainer/Panel/Mine/EndTurn/Timer
@onready var gradient_frame = $UI/HBoxContainer/VBoxContainer/Panel/Mine/TextureRect
@onready var shop_ui = $UI/HBoxContainer/VBoxContainer/Panel/Shop
@onready var shop_list = $UI/HBoxContainer/VBoxContainer/Panel/Shop/MarginContainer/VBoxContainer/MarginContainer/ScrollContainer/GridContainer
@onready var result_ui = $UI/HBoxContainer/VBoxContainer/Panel/Result
@onready var result_title = $UI/HBoxContainer/VBoxContainer/Panel/Result/VBoxContainer/Label
@onready var result_text = $UI/HBoxContainer/VBoxContainer/Panel/Result/VBoxContainer/Label2
@onready var result_button = $UI/HBoxContainer/VBoxContainer/Panel/Result/VBoxContainer/Button
@onready var deck_browser_ui = $UI/HBoxContainer/VBoxContainer/Panel/DeckBrowser
@onready var deck_browser_title1 = $UI/HBoxContainer/VBoxContainer/Panel/DeckBrowser/ScrollContainer/VBoxContainer/Label1
@onready var deck_browser_list1 = $UI/HBoxContainer/VBoxContainer/Panel/DeckBrowser/ScrollContainer/VBoxContainer/GridContainer1
@onready var deck_browser_title2 = $UI/HBoxContainer/VBoxContainer/Panel/DeckBrowser/ScrollContainer/VBoxContainer/Label2
@onready var deck_browser_list2 = $UI/HBoxContainer/VBoxContainer/Panel/DeckBrowser/ScrollContainer/VBoxContainer/GridContainer2
@onready var select_card_ui = $UI/HBoxContainer/VBoxContainer/Panel/SelectCard
@onready var select_card_title = $UI/HBoxContainer/VBoxContainer/Panel/SelectCard/PanelContainer/MarginContainer/VBoxContainer/Label
@onready var select_card_list = $UI/HBoxContainer/VBoxContainer/Panel/SelectCard/PanelContainer/MarginContainer/VBoxContainer/GridContainer
@onready var select_card_ok = $UI/HBoxContainer/VBoxContainer/Panel/SelectCard/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Button
@onready var select_card_cancel = $UI/HBoxContainer/VBoxContainer/Panel/SelectCard/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Button2
@onready var hand = $UI/HBoxContainer/VBoxContainer/Panel2/Hand
@onready var deck = $UI/HBoxContainer/VBoxContainer/Panel2/Deck
@onready var tooltip = $UI/ToolTip
@onready var tooltip_text = $UI/ToolTip/VBoxContainer/Text

static var tree : SceneTree = null
static var scene_root : SubViewport = null
static var fx_electric_node : Node2D = null
static var tilemap : TileMapLayer = null
static var tilemap_water : TileMapLayer = null
static var tilemap_convex : TileMapLayer = null
static var tilemap_floor2 : TileMapLayer = null
static var tilemap_convex2 : TileMapLayer = null
static var ore_root : Node2D = null
static var unit_root : Node2D = null
static var tilemap_overlay : Node2D = null
static var ui_root : CanvasLayer = null
static var cave_durability_text : Label = null
static var target_score_text : Label = null
static var turn_text : Label = null
static var deep_text : Label = null
static var gold_text : Label
static var ruby_texture : TextureRect
static var ruby_amount_text : Label
static var ruby_value_text : Label
static var emerald_texture : TextureRect
static var emerald_amount_text : Label
static var emerald_value_text : Label
static var sapphire_texture : TextureRect
static var sapphire_amount_text : Label
static var sapphire_value_text : Label
static var amethyst_texture : TextureRect
static var amethyst_amount_text : Label
static var amethyst_value_text : Label
static var energy_text : Label
static var state_text : RichTextLabel
const scene_off = Vector2(208, 7)

static var sfx_click : AudioStreamPlayer
static var sfx_hover : AudioStreamPlayer
static var sfx_open : AudioStreamPlayer
static var sfx_close : AudioStreamPlayer
static var sfx_error : AudioStreamPlayer
static var sfx_draw : AudioStreamPlayer
static var sfx_buy : AudioStreamPlayer
static var sfx_build : AudioStreamPlayer
static var sfx_shuffle : AudioStreamPlayer
static var sfx_pickup : AudioStreamPlayer
static var sfx_pickup_timer : Timer
static var sfx_sword : AudioStreamPlayer
static var sfx_monster_move : AudioStreamPlayer
static var sfx_monster_death : AudioStreamPlayer
static var sfx_pickaxe : AudioStreamPlayer
static var sfx_rocket_loop : AudioStreamPlayer
static var sfx_explosion : AudioStreamPlayer

var info_tween : Tween = null
var gold_text_tween : Tween = null
var ruby_value_text_tween : Tween = null
var emerald_value_text_tween : Tween = null
var sapphire_value_text_tween : Tween = null
var amethyst_value_text_tween : Tween = null
static var dragging_card : Card = null
var drag_offset : Vector2
var card_can_activate = false
var tooltip_using = false

var select_tile_callback : Callable

static func weighted_random(choices : Dictionary):
	var sum = 0
	for n in choices:
		sum += choices[n]
	var sel = randi_range(0, sum - 1)
	for n in choices:
		var w = choices[n]
		if sel < w:
			return n
		sel -= w

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
	var loop_start = 0
	var loop_end = 1
	ret.append(tile)
	while range > 0:
		for i in range(loop_start, loop_end):
			var t = ret[i]
			for _t in get_surrounding_tiles(t):
				if !ret.has(_t):
					ret.append(_t)
		loop_start = loop_end
		loop_end = ret.size()
		range -= 1
	return ret

static func dist_on_map(start : Vector2i, end : Vector2i):
	if start == end:
		return 0
	var start_tile = map[start]
	var end_tile = map[end]
	
	var cands = []
	cands.append(start_tile)
	var loop_start = 0
	var loop_end = 1
	var d = 1
	while d < 64:
		for i in range(loop_start, loop_end):
			var t = cands[i]
			for _t in get_surrounding_tiles(t):
				if _t == end_tile:
					return d
				if !cands.has(_t):
					cands.append(_t)
		loop_start = loop_end
		loop_end = cands.size()
		d += 1
	return d

static func find_path_on_map(start : Vector2i, end : Vector2i) -> Array[Tile]:
	var ret : Array[Tile] = []
	var start_tile = map[start]
	if !start_tile.passable:
		return []
	if start.x == end.x && start.y == end.y:
		ret.append(start_tile)
		return ret
	var end_tile = map[end]
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
func alert(text: String, timeout : float = 0.8):
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
	alert_tween.tween_interval(timeout)
	alert_tween.tween_callback(func():
		alert_panel.hide()
		alert_tween = null
	)

static func yes_no_dialog(text : String, callback : Callable):
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

static func get_resource_icon(type : int):
	match type:
		Gold:
			return "res://icons/gold.png"
		Ruby:
			return "res://icons/ruby.png"
		Emerald:
			return "res://icons/emerald.png"
		Sapphire:
			return "res://icons/sapphire.png"
		Amethyst:
			return "res://icons/amethyst.png"

static func add_resource(type : int, v : int, pos : Vector2):
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var text : String
	if v >= 0:
		text = "[color=white]+%d[/color]" % v
	else:
		text = "[color=red]%d[/color]" % v
	text += "[img=20]%s[/img]" % get_resource_icon(type)
	label.text = text
	label.position = Vector2(0, -100)
	label.add_theme_constant_override("outline_size", 5)
	label.z_index = 4
	ui_root.add_child(label)
	
	var tween = tree.create_tween()
	tween.tween_method(func(v : int):
		label.position = pos - Vector2(label.size.x * 0.5, v)
	, 0, 15, 0.3)
	tween.tween_callback(func():
		label.queue_free()
	)
	
	if type != Gold && v > 0:
		for i in v :
			tween.tween_callback(func():
				var sprite = Sprite2D.new()
				var tween2 = tree.create_tween()
				tween2.tween_callback(func():
					sprite.texture = load(get_resource_icon(type))
					sprite.scale = Vector2(0.3, 0.3)
					sprite.rotation_degrees = 30
					sprite.position = pos - Vector2(0, 20)
					ui_root.add_child(sprite)
				)
				var pos2 = Vector2(0, 0)
				if type == Ruby:
					pos2 = ruby_amount_text.global_position
				if type == Emerald:
					pos2 = emerald_amount_text.global_position
				if type == Sapphire:
					pos2 = sapphire_amount_text.global_position
				if type == Amethyst:
					pos2 = amethyst_amount_text.global_position
				tween2.tween_property(sprite, "position", pos2, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
				tween2.parallel().tween_property(sprite, "scale", Vector2(1, 1), 0.7)
				tween2.parallel().tween_property(sprite, "rotation_degrees", 0, 0.7)
				tween2.tween_callback(func():
					sprite.queue_free()
					match type:
						Ruby:
							player.add_ruby(1)
						Emerald:
							player.add_emerald(1)
						Sapphire:
							player.add_sapphire(1)
						Amethyst:
							player.add_amethyst(1)
				)
			)
			tween.tween_interval(0.12)
	else:
		tween.tween_callback(func():
			player.add_gold(v)
		)

func update_gold_text(o, n):
	if gold_text_tween:
		gold_text_tween.kill()
	gold_text_tween = tree.create_tween()
	gold_text_tween.tween_method(func(v):
			gold_text.text = "$%d" % v,
		o, n, 0.5
	)
	gold_text_tween.tween_callback(func():
		gold_text_tween = null
	)
	
	if shop_ui.visible:
		for i in shop_list.get_children():
			i.update_price()

static func shadow_up(node : Control):
	var pos = node.global_position
	var temp = node.duplicate(0)
	ui_root.add_child(temp)
	for n in temp.get_children():
		temp.remove_child(n)
		n.queue_free()
	temp.position = pos
	var tween = tree.create_tween()
	tween.tween_property(temp, "position", pos - Vector2(0, 15), 0.15)
	tween.parallel().tween_property(temp, "modulate:a", 0, 0.15)
	tween.tween_callback(func():
		temp.queue_free()
	)

static func shadow_expand(node : Control):
	var pos = node.global_position
	var temp = node.duplicate(0)
	ui_root.add_child(temp)
	for n in temp.get_children():
		temp.remove_child(n)
		n.queue_free()
	temp.scale = Vector2(1, 1)
	temp.position = pos
	temp.modulate = Color(1, 1, 1, 0.5)
	temp.pivot_offset = node.size / 2.0
	var tween = tree.create_tween()
	tween.tween_property(temp, "scale", Vector2(2, 2), 0.15)
	tween.parallel().tween_property(temp, "modulate:a", 0, 0.15)
	tween.tween_callback(func():
		temp.queue_free()
	)

static func update_cave_durability_text():
	cave.calc_damage()
	cave_durability_text.text = "耐久：%d(+%d-%d)" % [cave.durability, cave.reinforcement, cave.current_damage]

static func update_turn_text():
	turn_text.text = "回合：%d" % turn

static func update_deep_text():
	deep_text.text = "深度：%d" % deep

static func update_energy_text():
	energy_text.text = "%d/%d" % [player.energy, player.max_energy]

static func update_ruby_text(o, n):
	ruby_amount_text.text = "%03d" % n
	
	if n > o:
		ruby_texture.modulate = Color(1, 1, 1, 1)
		sfx_pickup.play()
		sfx_pickup.pitch_scale = min(sfx_pickup.pitch_scale + 0.1, 2.0)
		sfx_pickup_timer.start()
		shadow_expand(ruby_texture)
		shadow_up(ruby_amount_text)

static func update_ruby_value_text(o, n):
	ruby_value_text.text = "$%d" % n
	
	if n > o:
		shadow_expand(ruby_value_text)

static func update_emerald_text(o, n):
	emerald_amount_text.text = "%03d" % n
	
	if n > o:
		emerald_texture.modulate = Color(1, 1, 1, 1)
		sfx_pickup.play()
		sfx_pickup.pitch_scale = min(sfx_pickup.pitch_scale + 0.1, 2.0)
		sfx_pickup_timer.start()
		shadow_expand(emerald_texture)
		shadow_up(emerald_amount_text)

static func update_emerald_value_text(o, n):
	emerald_value_text.text = "$%d" % n
	
	if n > o:
		shadow_expand(emerald_value_text)

static func update_sapphire_text(o, n):
	sapphire_amount_text.text = "%03d" % n
	
	if n > o:
		sapphire_texture.modulate = Color(1, 1, 1, 1)
		sfx_pickup.play()
		sfx_pickup.pitch_scale = min(sfx_pickup.pitch_scale + 0.1, 2.0)
		sfx_pickup_timer.start()
		shadow_expand(sapphire_texture)
		shadow_up(sapphire_amount_text)

static func update_sapphire_value_text(o, n):
	sapphire_value_text.text = "$%d" % n
	
	if n > o:
		shadow_expand(sapphire_value_text)

static func update_amethyst_text(o, n):
	amethyst_amount_text.text = "%03d" % n
	
	if n > o:
		amethyst_texture.modulate = Color(1, 1, 1, 1)
		sfx_pickup.play()
		sfx_pickup.pitch_scale = min(sfx_pickup.pitch_scale + 0.1, 2.0)
		sfx_pickup_timer.start()
		shadow_expand(amethyst_texture)
		shadow_up(amethyst_amount_text)

static func update_amethyst_value_text(o, n):
	amethyst_value_text.text = "$%d" % n
	
	if n > o:
		shadow_expand(amethyst_value_text)

func create_card(dragable : bool = true) -> Card:
	var card = CardPrefab.instantiate()
	card.dragable = dragable
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
	if card.dragable:
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

func move_card_from_deck_to_hand(card : Card):
	ui_root.add_child(card)
	var p0 = deck.rect.global_position + Vector2(-30, -40)
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

func move_card_from_pos_to_deck(card : Card, p1 : Vector2):
	card.reparent(ui_root)
	card.lock = true
	var p0 = deck.rect.global_position + Vector2(-30, -40)
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
	unit_root.add_child(unit)
	return unit

static func add_ore(tile : Tile, type : int):
	if !tile.ore:
		var ore : Ore = OrePrefab.instantiate()
		ore.setup(type, tile.coord)
		tile.ore = ore
		ore_root.add_child(ore)
		return ore
	return null

static func random_ore(d : int) -> int:
	if d <= 2:
		return weighted_random({Ruby:67,Emerald:20,Sapphire:10,Amethyst:3})
	elif d <= 4:
		return weighted_random({Ruby:50,Emerald:30,Sapphire:15,Amethyst:5})
	elif d <= 6:
		return weighted_random({Ruby:30,Emerald:40,Sapphire:20,Amethyst:10})
	elif d <= 8:
		return weighted_random({Ruby:30,Emerald:30,Sapphire:20,Amethyst:20})
	else:
		return weighted_random({Ruby:25,Emerald:25,Sapphire:25,Amethyst:25})
	return -1

static var times_no_ore : int = 0
static var times_before_monster : int = 0
static func reveal(tile : Tile, range : int = 1):
	if tile.terrain == Tile.TerrainFloor2:
		if tile.coord != player.coord:
			if randf() < 0.2:
				add_ore(tile, random_ore(tile.dist_to_center))
				times_no_ore = 0
			else:
				times_no_ore += 1
				if times_no_ore >= 4:
					times_no_ore = 0
					add_ore(tile, random_ore(tile.dist_to_center))
			if times_before_monster >= 3:
				if randf() < 0.2:
					add_unit("monster", tile.coord, true)
					times_before_monster = 0
			else:
				times_before_monster += 1
		tile.terrain = Tile.TerrainFloor
		tile.passable = true
	if range > 0:
		for t in get_surrounding_tiles(tile):
			reveal(t, range - 1)

static func dig(tile : Tile, damage : int = 4, use_animation = true, reveal_range : int = 1):
	reveal(tile, reveal_range)
	update_tiles()
	
	var resource_type = Gold
	var amount = 0
	if tile.ore:
		if tile.ore.fragile:
			damage *= 2
		resource_type = tile.ore.type
		tile.ore.hp = max(0, tile.ore.hp - damage)
		amount = (tile.ore.last_minerals_hp - tile.ore.hp) / 4
		if amount > 0:
			tile.ore.last_minerals_hp = tile.ore.hp
		if resource_type == Gold:
			amount *= 100
	
	if damage > 0:
		cave.current_damage += 1
		update_cave_durability_text()
	
	var pos = tilemap.to_global(tilemap.map_to_local(tile.coord))
	if use_animation:
		var tween = tree.create_tween()
		var crack_sprite = Sprite2D.new()
		tween.tween_callback(func():
			sfx_pickaxe.play(0.33)
			crack_sprite.texture = load("res://fx/crack.png")
			crack_sprite.position = pos
			scene_root.add_child(crack_sprite)
			
			reveal(tile)
			update_tiles()
		)
		tween.tween_interval(0.5)
		if amount > 0:
			tween.parallel().tween_callback(func():
				add_resource(resource_type, amount, pos + tilemap.get_canvas_transform().origin + scene_off - Vector2(0, 20))
			)
		tween.parallel().tween_property(crack_sprite, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(func():
			crack_sprite.queue_free()
		)
	else:
		if amount > 0:
			add_resource(resource_type, amount, pos + tilemap.get_canvas_transform().origin + scene_off - Vector2(0, 20))
	return amount

static func reinforce_cave(value : int):
	cave.reinforcement += value
	update_cave_durability_text()

static func attack(tile : Tile, damage : int = 4, use_animation = true):
	if use_animation:
		var slash_sprite = Sprite2D.new()
		var pos = tilemap.to_global(tilemap.map_to_local(tile.coord))
		var tween = tree.create_tween()
		tween.tween_callback(func():
			sfx_sword.play()
			slash_sprite.texture = load("res://fx/slash.png")
			slash_sprite.scale = Vector2(0.8, 0.8)
			slash_sprite.position = pos
			scene_root.add_child(slash_sprite)
			
			for m in tile.monsters:
				m.take_damage(damage)
		)
		tween.tween_interval(0.5)
		tween.tween_callback(func():
			slash_sprite.queue_free()
		)
	else:
		for m in tile.monsters:
			m.take_damage(damage)

func process_battle(tile : Tile):
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

func new_turn():
	turn += 1
	player.calc_max_energy()
	player.restore_energy()
	
	info_ui.modulate.a = 1
	info_ui.show()
	info_text.text = "回合%d" % turn
	if info_tween != null:
		info_tween.kill()
		info_tween = null
	info_tween = tree.create_tween()
	info_tween.tween_interval(0.5)
	info_tween.tween_property(info_ui, "modulate:a", 0, 0.3)
	info_tween.tween_callback(func():
		info_ui.hide()
		info_tween = null
	)
	
	update_cave_durability_text()
	update_turn_text()
	
	var tween = tree.create_tween()
	for c in player.buildings:
		var building = player.buildings[c]
		var tile = map[c]
		
		var pos = tilemap.to_global(tilemap.map_to_local(c))
		tween.tween_interval(0.15)
		tween.tween_callback(func():
			camera.move_to(pos)
		)
		tween.tween_interval(0.2)
		
		if building.effect.has("category") && building.effect["category"] == "every_turn":
			if building.effect.has("type"):
				var effect_type = building.effect["type"]
				if effect_type == "dig":
					tween.tween_callback(func():
						dig(tile)
					)
				elif effect_type == "summon":
					var unit_name = building.effect["name"]
					var num = building.effect["num"]
					for i in num:
						tween.tween_interval(0.25)
						tween.tween_callback(func():
							var unit = add_unit(unit_name, tile.coord, false)
						)
	
	tween.tween_callback(func():
		sfx_shuffle.play()
	)
	for i in 5:
		tween.tween_callback(func():
			var card = deck.draw()
			if card:
				move_card_from_deck_to_hand(card)
		)
		tween.tween_interval(0.1)

func change_state(new_state : int, data : Dictionary) :
	state = new_state
	if state == SelectCaveState:
		shop_ui.hide()
		
		state_text.text = "[wave amp=50.0 freq=3.0 connected=1]选择一个矿洞[/wave]"
		
		cave_index += 1
		if cave_index % 3 == 0:
			cave_index = 0
			deep += 1
			update_deep_text()
		var base_scores = [300, 800, 2000, 5000, 11000, 20000, 35000, 50000]
		var base_score = base_scores[deep - 1]
		
		var cand1 = Cave.new()
		cand1.name = "普通的矿洞"
		cand1.target_score = base_score * 1.0
		cand1.collapse_turn = 3
		cave_candidates.append(cand1)
		var cand2 = Cave.new()
		cand2.name = "困难的矿洞"
		cand2.target_score = base_score * 1.5
		cand2.collapse_turn = 3
		cave_candidates.append(cand2)
		var cand3 = Cave.new()
		cand3.name = "残酷的矿洞"
		cand3.target_score = base_score * 2.0
		cand3.collapse_turn = 3
		cave_candidates.append(cand3)
		var update_cand_ui = func(ui : Control, cand : Cave, disable : bool):
			ui.find_child("Name").text = cand.name
			ui.find_child("TargetScore").text = "目标：$%d" % cand.target_score
			if disable:
				ui.find_child("Button").disabled = true
		update_cand_ui.call(cave_candidate1_ui, cand1, cave_index % 3 != 0)
		update_cand_ui.call(cave_candidate2_ui, cand2, cave_index % 3 != 1)
		update_cand_ui.call(cave_candidate3_ui, cand3, cave_index % 3 != 2)
		cave_select_ui.show()
	elif state == MineState:
		turn = 0
		tilemap_water.modulate.a = 0
		water_level = 0
		deck.reset()
		
		cave = cave_candidates[data.select]
		cave_candidates.clear()
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
		
		for c in map:
			var d = dist_on_map(player.coord, c)
			map[c].dist_to_center = d
			if d <= 2:
				pass
		
		reveal(map[player.coord], 1)
		update_tiles()
		
		camera.position = tilemap.map_to_local(tilemap.get_used_rect().get_center())
		
		tilemap_overlay.update_border()
	
		state_text.text = cave.name
		target_score_text.text = "目标：$%d" % cave.target_score
		update_cave_durability_text()
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
			"terrain": tile.terrain
		}
		_map[c] = t
	saving["map"] = _map
	var _buildings = {}
	for c in player.buildings:
		var building = player.buildings[c] as Building
		var b = {
			"name": building.building_name,
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
	
	var _hand = json["hand"]
	for c in _hand:
		if c.type == Card.NormalCard:
			pass
		elif c.type == Card.BuildingCard:
			var card = create_card()
			card.setup_building_card(c.name.substr(0, c.name.length() - 9))
			hand.add_child(card)
			pass
		elif c.type == Card.UnitCard:
			var card = create_card()
			card.setup_unit_card(c.name.substr(0, c.name.length() - 5))
			hand.add_child(card)

func on_sell_ruby() -> void:
	if player.ruby_amount > 0:
		player.add_ruby(-1)
		player.add_gold(player.ruby_value)
		sfx_buy.play()
		if player.ruby_amount == 0:
			ruby_texture.modulate = Color(0.5, 0.5, 0.5, 1)

func on_sell_emerald() -> void:
	if player.emerald_amount > 0:
		player.add_emerald(-1)
		player.add_gold(player.emerald_value)
		sfx_buy.play()
		if player.emerald_amount == 0:
			emerald_texture.modulate = Color(0.5, 0.5, 0.5, 1)

func on_sell_sapphire() -> void:
	if player.sapphire_amount > 0:
		player.add_sapphire(-1)
		player.add_gold(player.sapphire_value)
		sfx_buy.play()
		if player.sapphire_amount == 0:
			sapphire_texture.modulate = Color(0.5, 0.5, 0.5, 1)

func on_sell_amethyst() -> void:
	if player.amethyst_amount > 0:
		player.add_amethyst(-1)
		player.add_gold(player.amethyst_value)
		sfx_buy.play()
		if player.amethyst_amount == 0:
			amethyst_texture.modulate = Color(0.5, 0.5, 0.5, 1)

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
	if card_type == Card.NormalCard:
		shop_item.find_child("Card").setup(name)
		shop_item.setup(use_resource, cost)
	elif card_type == Card.BuildingCard:
		shop_item.find_child("Card").setup_building_card(name)
		shop_item.setup(use_resource, cost)
	elif card_type == Card.UnitCard:
		shop_item.find_child("Card").setup_unit_card(name)
		shop_item.setup(use_resource, cost)
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
		if player.get_resource(shop_item.use_resource) >= shop_item.resource_amount:
			add_resource(shop_item.use_resource, -shop_item.resource_amount, shop_item.card.global_position + shop_item.card.size / 2.0)
			var effect = shop_item.card.effect
			if !effect.is_empty():
				shop_item.queue_free()
				
				var effect_type = effect["type"]
				if effect_type == "value_up":
					var target = effect["target"]
					match target:
						"ruby":
							Game.player.add_ruby_value(effect["value"])
						"emerald":
							Game.player.add_emerald_value(effect["value"])
						"sapphire":
							Game.player.add_sapphire_value(effect["value"])
						"amethyst":
							Game.player.add_amethyst_value(effect["value"])
				elif effect_type == "delete_card":
					select_cards("选择你要删除的卡", "all", 1, 1, func(cards : Array):
						if cards.size() == 1:
							var card_name = cards[0].card_name
							for i in deck.draw_pile.size():
								if deck.draw_pile[i].card_name == card_name:
									deck.draw_pile.remove_at(i)
									break
					)
			else:
				shop_item.queue_free()
				
				move_card_from_pos_to_deck(shop_item.card, shop_item.global_position)
				deck.add_card(shop_item.card)
			sfx_buy.play()
		else:
			alert("金币不足")
			sfx_error.play()
	)
	shop_list.add_child(shop_item)

func update_shop_list():
	for n in shop_list.get_children():
		shop_list.remove_child(n)
		n.queue_free()
	add_shop_item(Card.NormalCard, "ruby_value_upgrade", Gold, 100, 1)
	add_shop_item(Card.NormalCard, "emerald_value_upgrade", Gold, 100, 1)
	add_shop_item(Card.NormalCard, "sapphire_value_upgrade", Gold, 100, 1)
	add_shop_item(Card.NormalCard, "amethyst_value_upgrade", Gold, 100, 1)
	add_shop_item(Card.NormalCard, "delete_card", Gold, 100, 1)
	var normal_card_pool = []
	var building_card_pool = []
	normal_card_pool.append("shield")
	normal_card_pool.append("smash")
	normal_card_pool.append("drone_reinforcements")
	normal_card_pool.append("machine_duplication")
	normal_card_pool.append("rocket_box")
	normal_card_pool.append("discharge")
	normal_card_pool.append("release_water")
	normal_card_pool.append("acidic_agent")
	building_card_pool.append("digging_machine")
	building_card_pool.append("energy_storage")
	building_card_pool.append("drone_factory")
	building_card_pool.append("repeater")
	for i in 4:
		var name = normal_card_pool.pick_random()
		add_shop_item(Card.NormalCard, name, Gold, 100, 1)
	for i in 4:
		var name = building_card_pool.pick_random()
		add_shop_item(Card.BuildingCard, name, Gold, 100, 1)

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

static var show_end_turn_warning = true
func on_end_turn() -> void:
	if tree.get_processed_tweens().is_empty():
		sfx_click.play()
		cave.durability -= cave.current_damage - cave.reinforcement
		cave.current_damage = 0
		cave.reinforcement = 0
		if cave.durability <= 0:
			if player.gold >= cave.target_score:
				player.add_gold(-cave.target_score)
				change_state(ResultState, { "gameover": false })
			else:
				if show_end_turn_warning:
					show_end_turn_warning = false
					alert("未达到要求，继续将会扣除信用。（出售宝石以获得金钱）\n再次点击继续。", 2.0)
					end_turn_timer.timeout.connect(func():
						show_end_turn_warning = true
					)
					end_turn_timer.start()
				else:
					change_state(ResultState, { "gameover": true })
		else:
			var tween = tree.create_tween()
			tween.tween_interval(0.5)
			
			var num_hand = hand.get_child_count()
			if num_hand > 0:
				tween.tween_callback(func():
					sfx_shuffle.play()
				)
				for i in num_hand:
					var c = hand.get_child(i)
					tween.tween_callback(func():
						var p1 = hand.global_position + hand.get_card_pos(i)
						move_card_from_pos_to_deck(c, p1)
					)
					tween.tween_interval(0.1)
			
			tween.tween_interval(0.1)
			for c in map:
				var tile = map[c]
				var temp_units : Array[Unit] = []
				for u in tile.player_units:
					temp_units.append(u)
				for u in temp_units:
					var enemies : Array[Tile]
					var ores : Array[Tile]
					for cc in map:
						var tile2 = map[cc]
						if !tile2.monsters.is_empty():
							enemies.append(tile)
						if tile2.ore:
							ores.append(tile)
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
						tween.tween_callback(func():
							process_battle(tile)
							if u.hp > 0 && u.atk > 0:
								dig(tile, u.atk, false, 0)
						)
				var temp_monsters : Array[Unit] = []
				for u in tile.monsters:
					temp_monsters.append(u)
				for m in temp_monsters:
					var path = find_path_on_map(m.coord, player.coord)
					if path.size() > 1:
						tween.tween_callback(func():
							m.move_to(path[1].coord)
							m.update_pos()
							sfx_monster_move.play()
						)
						tween.tween_interval(0.25)
						tween.tween_callback(func():
							process_battle(tile)
						)
				tween.tween_callback(func():
					if !tile.monsters.is_empty():
						player.remove_building(tile.coord)
				)
			tween.tween_callback(func():
				new_turn()
			)

func copy_card_undragable(src : Card):
	var card = create_card(false)
	card.setup_from_data(inst_to_dict(src))
	return card

func on_deck_clicked() -> void:
	if !deck_browser_ui.visible:
		if state == MineState:
			deck_browser_title1.text = "抽牌堆"
			for c in deck.draw_pile:
				deck_browser_list1.add_child(copy_card_undragable(c))
			deck_browser_title2.text = "弃牌堆"
			for c in deck.discard_pile:
				deck_browser_list2.add_child(copy_card_undragable(c))
		else:
			var cards = []
			for c in deck.cards:
				cards.append(copy_card_undragable(c))
			cards.sort_custom(func(a, b): 
				return a.card_name < b.card_name
			)
			deck_browser_title1.text = "你的卡组"
			for c in cards:
				deck_browser_list1.add_child(c)
		deck_browser_ui.show()
	else:
		clear_deck_browser()
		deck_browser_ui.hide()
	sfx_click.play()

func clear_deck_browser():
	deck_browser_title1.text = ""
	for n in deck_browser_list1.get_children():
		deck_browser_list1.remove_child(n)
		n.queue_free()
	deck_browser_title2.text = ""
	for n in deck_browser_list2.get_children():
		deck_browser_list2.remove_child(n)
		n.queue_free()

func on_deck_browser_close() -> void:
	clear_deck_browser()
	deck_browser_ui.hide()
	sfx_click.play()

func on_select_cards() -> void:
	if select_card_callback.is_valid():
		var selecteds = []
		for c in select_card_list.get_children():
			if c.selected:
				selecteds.append(c)
		select_card_callback.call(selecteds)
		select_card_callback = Callable()
	for n in select_card_list.get_children():
		select_card_list.remove_child(n)
		n.queue_free()
	select_card_ui.hide()

func on_select_cards_cancel() -> void:
	select_card_callback = Callable()
	for n in select_card_list.get_children():
		select_card_list.remove_child(n)
		n.queue_free()
	select_card_ui.hide()

var select_card_min : int = -1
var select_card_max : int = -1
var select_card_callback : Callable

func update_select_button():
	var num = 0
	for c in select_card_list.get_children():
		if c.selected:
			num += 1
	if select_card_min == select_card_max:
		select_card_ok.text = "选择%d张卡（%d已选择）" % [select_card_min, num]
		select_card_ok.disabled = select_card_min != num

func select_cards(title : String, type : String, min_num : int, max_num : int, callback : Callable, can_cancel : bool = true):
	select_card_min = min_num
	select_card_max = max_num
	select_card_callback = callback
	
	select_card_title.text = title
	if type == "all":
		var cards = []
		for c in deck.cards:
			cards.append(copy_card_undragable(c))
		cards.sort_custom(func(a, b):
			return a.card_name < b.card_name
		)
		for c in cards:
			select_card_list.add_child(c)
	for c in select_card_list.get_children():
		c.clicked.connect(func():
			if !c.selected:
				c.select()
			else:
				c.deselect()
			update_select_button()
			sfx_click.play()
		)
	update_select_button()
	select_card_cancel.disabled = !can_cancel
	select_card_ui.show()

func on_continue() -> void:
	sfx_click.play()
	if state == ResultState:
		if gameover:
			pass
		else:
			change_state(ShoppingState, {})
	elif state == ShoppingState:
		change_state(SelectCaveState, {})

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
			tilemap.set_cell(coord, -1)
			tilemap_water.set_cell(coord, -1)
			tilemap_convex.set_cell(coord, -1)
			tilemap_floor2.set_cell(coord, -1)
			tilemap_convex2.set_cell(coord, -1)

	for x in range(-1, cx / 4 + 1):
		for y in range(-1, cy / 3 + 1):
			var coord = Vector2i(x, y)
			tilemap_water.set_cell(coord, 0, Vector2i(0, 0))
	
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
			tilemap_floor2.set_cell(c, 0, Vector2i(rns[c.y * cx + c.x], 0))
	
	map_rng.state = rng_state

func new_game():
	deep = 0
	gameover = false
	
	player = Player.new(0)
		
	player.energy_changed.connect(update_energy_text)
	player.gold_changed.connect(update_gold_text)
	player.ruby_changed.connect(update_ruby_text)
	player.ruby_value_changed.connect(update_ruby_value_text)
	player.emerald_changed.connect(update_emerald_text)
	player.emerald_value_changed.connect(update_emerald_value_text)
	player.sapphire_changed.connect(update_sapphire_text)
	player.sapphire_value_changed.connect(update_sapphire_value_text)
	player.amethyst_changed.connect(update_amethyst_text)
	player.amethyst_value_changed.connect(update_amethyst_value_text)
	update_gold_text(0, player.gold)
	update_ruby_text(0, player.ruby_amount)
	update_ruby_value_text(0, player.ruby_value)
	update_emerald_text(0, player.emerald_amount)
	update_emerald_value_text(0, player.emerald_value)
	update_sapphire_text(0, player.sapphire_amount)
	update_sapphire_value_text(0, player.sapphire_value)
	update_amethyst_text(0, player.amethyst_amount)
	update_amethyst_value_text(0, player.amethyst_value)
	
	for n in hand.get_children():
		n.queue_free()
	for c in deck.draw_pile:
		c.queue_free()
	deck.draw_pile.clear()
	for c in deck.discard_pile:
		c.queue_free()
	deck.discard_pile.clear()
	for i in 5:
		var card = create_card()
		card.setup("dig")
		deck.add_card(card)
	for i in 5:
		var card = create_card()
		card.setup("reinforce")
		deck.add_card(card)
	for i in 1:
		var card = create_card()
		card.setup("attack")
		deck.add_card(card)
	#for i in 1:
	#	var card = create_card()
	#	card.setup_building_card("digging_machine")
	#	deck.add_card(card)
	deck.reset()
	
	change_state(ShoppingState, {})

func _ready() -> void:
	seed(Time.get_ticks_msec())
	
	tree = get_tree()
	scene_root = $Scene
	fx_electric_node = $Scene/FxElectric
	tilemap = $Scene/TileMapLayerMain
	tilemap_water = $Scene/TileMapLayerWater
	tilemap_convex = $Scene/TileMapLayerConvex
	tilemap_floor2 = $Scene/TileMapLayerFloor2
	tilemap_convex2 = $Scene/TileMapLayerConvex2
	ore_root = $Scene/OreRoot
	unit_root = $Scene/UnitRoot
	tilemap_overlay = $Scene/TileMapOverlay
	ui_root = $UI
	cave_durability_text = $UI/HBoxContainer/Panel/VBoxContainer/CaveDurability
	target_score_text = $UI/HBoxContainer/Panel/VBoxContainer/TargetScore
	turn_text = $UI/HBoxContainer/Panel/VBoxContainer/Turn
	deep_text = $UI/HBoxContainer/Panel/VBoxContainer/Deep
	gold_text = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer/Gold
	ruby_texture = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer1/TextureRect
	ruby_amount_text = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer1/Label
	ruby_value_text = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer1/TextureRect/Label
	emerald_texture = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer2/TextureRect
	emerald_amount_text = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer2/Label
	emerald_value_text = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer2/TextureRect/Label
	sapphire_texture = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer3/TextureRect
	sapphire_amount_text = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer3/Label
	sapphire_value_text = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer3/TextureRect/Label
	amethyst_texture = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer4/TextureRect
	amethyst_amount_text = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer4/Label
	amethyst_value_text = $UI/HBoxContainer/Panel/VBoxContainer/HBoxContainer4/TextureRect/Label
	energy_text = $UI/HBoxContainer/VBoxContainer/Panel/Mine/EnergyText
	state_text = $UI/HBoxContainer/Panel/VBoxContainer/State
	
	sfx_click = $Sound/Click
	sfx_hover = $Sound/Hover
	sfx_error = $Sound/Error
	sfx_draw = $Sound/Draw
	sfx_buy = $Sound/Buy
	sfx_open = $Sound/Open
	sfx_close = $Sound/Close
	sfx_build = $Sound/Build
	sfx_shuffle = $Sound/Shuffle
	sfx_pickup = $Sound/PickUp
	sfx_pickup_timer = $Sound/PickUp/Timer
	sfx_pickup_timer.timeout.connect(func():
		sfx_pickup.pitch_scale = 1.0
	)
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
			card_can_activate = true
	)
	mine_ui.mouse_exited.connect(func():
		if dragging_card && dragging_card.target_type == Card.TargetNull:
			gradient_frame.modulate = Color(1.0, 1.0, 1.0, 0.15)
			card_can_activate = false
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
		if card_can_activate:
			if player.get_energy(card.cost_energy):
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
					elif effect_type == "reinforce":
						var value = card.effect["value"]
						tween.tween_callback(func():
							reinforce_cave(value)
						)
					elif effect_type == "draw":
						tween.tween_callback(func():
							var card2 = deck.draw()
							if card2:
								move_card_from_deck_to_hand(card2)
						)
						tween.tween_interval(0.2)
					elif effect_type == "search":
						var range = card.effect["range"]
						select_cards("选择一张卡", range, 1, 1, func(cards : Array):
							if cards.size() == 0:
								var card2 = cards[0]
								deck.draw_pile.erase(card2)
								move_card_from_deck_to_hand(card2)
						)
					elif effect_type == "release_water":
						tween.tween_property(tilemap_water, "modulate:a", 0.5, 0.85)
						tween.tween_callback(func():
							water_level = min(water_level + 1, 3)
						)
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
							if player.get_energy(card.cost_energy):
								card_applied(card, tween)
								card_used = true
								
								var damage = 4
								if card.effect.has("damage"):
									damage = card.effect["damage"]
								var extra = ""
								if card.effect.has("extra"):
									extra = card.effect["extra"]
								tween.tween_callback(func():
									dig(tile, damage)
									attack(tile, 2, false)
									if extra == "fragile":
										if tile.ore:
											tile.ore.set_fragile()
								)
							else:
								error_message = "能量不足"
						elif effect_type == "attack":
							if player.get_energy(card.cost_energy):
								card_applied(card, tween)
								card_used = true
								
								tween.tween_callback(func():
									attack(tile, 4)
									dig(tile, 2, false, 0)
								)
							else:
								error_message = "能量不足"
						elif effect_type == "shield":
							if tile.building:
								if player.get_energy(card.cost_energy):
									card_applied(card, tween)
									card_used = true
									
									tween.tween_callback(func():
										tile.building.shield = true
									)
								else:
									error_message = "能量不足"
							else:
								error_message = "需要建筑"
						elif effect_type == "rocket":
							if player.get_energy(card.cost_energy):
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
									scene_root.add_child(rocket_sprite)
									sfx_rocket_loop.play()
								)
								tween.tween_property(rocket_sprite, "position", pos, t)
								tween.tween_callback(func():
									explosion_sprite.sprite_frames = explosion_frames
									explosion_sprite.play("default")
									explosion_sprite.scale = Vector2(0.2, 0.2)
									explosion_sprite.position = pos
									scene_root.add_child(explosion_sprite)
									rocket_sprite.queue_free()
									sfx_rocket_loop.stop()
									sfx_explosion.play()
									ui_root.trigger_shake(60.0)
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
							if player.get_energy(card.cost_energy):
								card_applied(card, tween)
								card_used = true
								
								var unit_name = card.effect["name"]
								var num = card.effect["num"]
								for i in num:
									tween.tween_interval(0.25)
									tween.tween_callback(func():
										var unit = add_unit(unit_name, tile.coord, false)
									)
							else:
								error_message = "能量不足"
						elif effect_type == "levelup_pickaxe":
							if player.get_energy(card.cost_energy):
								card_applied(card, tween)
								card_used = true
								
								var damage = card.effect["damage"] * 4
								var ore_type = card.effect["ore"]
								tween.tween_callback(func():
									if dig(tile, damage) > 0:
										if tile.ore:
											if tile.ore.type == Gold && ore_type == "gold":
												card.effect["damage"] += 1
											elif tile.ore.type == Ruby && ore_type == "ruby":
												card.effect["damage"] += 1
											elif tile.ore.type == Emerald && ore_type == "emerald":
												card.effect["damage"] += 1
											elif tile.ore.type == Sapphire && ore_type == "sapphire":
												card.effect["damage"] += 1
											elif tile.ore.type == Amethyst && ore_type == "amethyst":
												card.effect["damage"] += 1
									attack(tile, 2, false)
								)
							else:
								error_message = "能量不足"
						elif effect_type == "discharge":
							if player.get_energy(card.cost_energy):
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
											induction_sprite.scale = Vector2(2.0, 2.0)
											induction_sprite.play("default")
											induction_sprite.position = tilemap.to_global(tilemap.map_to_local(t.coord))
											fx_electric_node.add_child(induction_sprite)
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
												if !discharged_tiles.has(tt) && tt.terrain != Tile.TerrainFloor2:
													newly_charge_tiles[tt] = charge - 1
									charged_tiles.clear()
									tween.tween_interval(0.3)
							else:
								error_message = "能量不足"
						elif effect_type == "acid":
							if player.get_energy(card.cost_energy):
								card_applied(card, tween)
								card_used = true
								
								if tile.ore:
									tile.ore.add_acid(2)
							else:
								error_message = "能量不足"
				elif card.type == Card.BuildingCard:
					if !tile.building:
						var building_name = card.card_name.substr(0, card.card_name.length() - 9)
						var info = Building.get_info(building_name)
						if info.need_terrain.find(tile.terrain) != -1:
							if player.get_energy(card.cost_energy):
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
	tilemap_overlay.queue_redraw()
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
				var text = "%s" % t.get_terrain_text()
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
