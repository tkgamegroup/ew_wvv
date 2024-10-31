extends Node2D

const Camera = preload("res://camera.gd")
const Tilemap = preload("res://tilemap.gd")
const TilemapOverlay = preload("res://tilemap_overlay.gd")
const CardBasePrefab = preload("res://card_ui_base.tscn")
const CardPrefab = preload("res://card_ui.tscn")
const CardShadowPrefab = preload("res://card_ui_shadow.tscn")
const ShopItemPrefab = preload("res://shop_item_ui.tscn")
const TechItemPrefab = preload("res://tech_item_ui.tscn")
const BattleUnitPrefab = preload("res://battle_unit.tscn")

@onready var tilemap_water = $TileMapLayerWater
@onready var tilemap_dirt = $TileMapLayerDirt
@onready var tilemap = $TileMapLayerMain
@onready var tilemap_object = $TileMapLayerObject
@onready var tilemap_overlay = $TileMapOverlay
@onready var camera = $Camera2D
@onready var scene_root = $"."
@onready var ui_root = $CanvasLayer
@onready var state_text = $CanvasLayer/StateTip/VBoxContainer/HBoxContainer/Label
@onready var round_tip = $CanvasLayer/RoundTip
@onready var round_text = $CanvasLayer/RoundTip/MarginContainer/Label
@onready var tips_text = $CanvasLayer/StateTip/VBoxContainer/Label2
@onready var show_tips_button = $CanvasLayer/StateTip/VBoxContainer/HBoxContainer/Button
@onready var alert_panel = $CanvasLayer/Alert
@onready var alert_text = $CanvasLayer/Alert/Panel/MarginContainer/Label
@onready var deconstruct_button = $CanvasLayer/Panels/HBoxContainer/Deconstruct
@onready var comfire_button = $CanvasLayer/Control/ComfireButton
@onready var cancel_button = $CanvasLayer/Control/CancelButton
@onready var resource_panel = $CanvasLayer/ResourcePanel
@onready var production_text = $CanvasLayer/ResourcePanel/HBoxContainer/Production
@onready var gold_text = $CanvasLayer/ResourcePanel/HBoxContainer2/Gold
@onready var science_text = $CanvasLayer/ResourcePanel/HBoxContainer3/Science
@onready var food_text = $CanvasLayer/ResourcePanel/HBoxContainer4/Food
@onready var hand = $CanvasLayer/HandContainer/Hand
@onready var shop_ui = $CanvasLayer/Shop
@onready var shop_tab_bar = $CanvasLayer/Shop/VBoxContainer/TabBar
@onready var shop_list = $CanvasLayer/Shop/VBoxContainer/GridContainer
@onready var action_text = $CanvasLayer/Control/Label
@onready var attack_troop_mark = $AttackTroop
@onready var defend_troop_mark = $DefendTroop
@onready var battle_ui = $CanvasLayer/Battle
@onready var battle_list1 = $CanvasLayer/Battle/Side1
@onready var battle_list2 = $CanvasLayer/Battle/Side2
@onready var tech_ui = $CanvasLayer/TechTree
@onready var tech_tree = $CanvasLayer/TechTree/VBoxContainer/ScrollContainer/Panel
@onready var tooltip = $CanvasLayer/ToolTip
@onready var tooltip_text = $CanvasLayer/ToolTip/VBoxContainer/Text
@onready var sfx_hover = $Sound/Hover
@onready var sfx_open = $Sound/Open
@onready var sfx_close = $Sound/Close
@onready var sfx_error = $Sound/Error
@onready var sfx_draw = $Sound/Draw
@onready var sfx_buy = $Sound/Buy
@onready var sfx_build = $Sound/Build
@onready var sfx_shuffle = $Sound/Shuffle

var round_tip_tween : Tween = null
var production_text_tween : Tween = null
var gold_text_tween : Tween = null
var science_text_tween : Tween = null
var food_text_tween : Tween = null
var shop_using : bool = false
var dragging_card : Card = null
var drag_offset : Vector2
var tooltip_using = false

var select_tile_callback : Callable

var alert_tween : Tween = null
func alert(text: String):
	if alert_tween != null:
		alert_tween.kill()
		alert_tween = null
	alert_panel.show()
	alert_panel.add_theme_constant_override("margin_top", 50)
	alert_text.text = text
	alert_tween = get_tree().create_tween()
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
		
func add_resource(type : int, v : int, pos : Vector2, parent_node : Node = ui_root):
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
	if type == Game.ProductionResource:
		text += "[img=20]res://icons/production.png[/img]"
	elif type == Game.GoldResource:
		text += "[img=20]res://icons/gold.png[/img]"
	elif type == Game.ScienceResource:
		text += "[img=20]res://icons/science.png[/img]"
	elif type == Game.FoodResource:
		text += "[img=20]res://icons/food.png[/img]"
	label.text = text
	label.position = pos
	parent_node.add_child(label)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(label, "position", pos - Vector2(0, 5), 0.2)
	tween2.tween_callback(func():
		if type == Game.ProductionResource:
			Game.main_player.add_production(v)
		elif type == Game.GoldResource:
			Game.main_player.add_gold(v)
		elif type == Game.ScienceResource:
			Game.main_player.add_science(v)
		elif type == Game.FoodResource:
			Game.main_player.add_food(v)
	)
	tween2.tween_property(label, "position", pos - Vector2(0, 10), 0.2)
	tween2.tween_callback(func():
		label.queue_free()
	)

func update_production(o, n):
	if production_text_tween:
		production_text_tween.kill()
	production_text_tween = get_tree().create_tween()
	production_text_tween.tween_method(func(v):
			production_text.text = "%d" % v,
		o, n, 0.5
	)
	production_text_tween.tween_callback(func():
		production_text_tween = null
	)
	
	if shop_ui.visible:
		update_shop_list()

func update_gold(o, n):
	if gold_text_tween:
		gold_text_tween.kill()
	gold_text_tween = get_tree().create_tween()
	gold_text_tween.tween_method(func(v):
			gold_text.text = "%d" % v,
		o, n, 0.5
	)
	gold_text_tween.tween_callback(func():
		gold_text_tween = null
	)
	
	if shop_ui.visible:
		update_shop_list()

func update_science(o, n):
	if science_text_tween:
		science_text_tween.kill()
	science_text_tween = get_tree().create_tween()
	science_text_tween.tween_method(func(v):
			science_text.text = "%d" % v,
		o, n, 0.5
	)
	science_text_tween.tween_callback(func():
		science_text_tween = null
	)

func update_food(o, n):
	if food_text_tween:
		food_text_tween.kill()
	food_text_tween = get_tree().create_tween()
	food_text_tween.tween_method(func(v):
			food_text.text = "%d" % v,
		o, n, 0.5
	)
	food_text_tween.tween_callback(func():
		food_text_tween = null
	)
	
	if shop_ui.visible:
		update_shop_list()
	
func add_hand_card():
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
		if card.target_type == Card.TargetNull:
			pass
		elif card.target_type == Card.TargetTroop:
			if !card.selected:
				card.select()
				Game.main_player.move_unit_to_troop(card.card_name.substr(0, card.card_name.length() - 5))
				if Game.main_player.troop_units.size() == 1 && Game.battle_attacker == Game.main_player_id:
					select_tile_callback = Callable(func(coord : Vector2i, is_peeding : bool):
						Game.main_player.troop_target = coord
						if !is_peeding:
							if coord.x == -1 && coord.y == -1:
								Game.main_player.troop_path.clear()
								tilemap_overlay.queue_redraw()
						else:
							if coord.x != -1 && coord.y != -1:
								var shortest_path : Array[Tile] = []
								var shortest_dist = 1000
								for c in Game.main_player.territories:
									var path = Game.find_path_on_map(c, coord, Game.main_player.vision)
									if !path.is_empty() && path.size() < shortest_dist:
										shortest_dist = path.size()
										shortest_path = path
								Game.main_player.troop_path = shortest_path
								tilemap_overlay.queue_redraw()
							else:
								Game.main_player.troop_path.clear()
								tilemap_overlay.queue_redraw()
					)
			else:
				card.deselect()
				Game.main_player.move_unit_from_troop(card.card_name.substr(0, card.card_name.length() - 5))
				if Game.main_player.troop_units.is_empty():
					select_tile_callback = Callable()
		else:
			if dragging_card != null:
				release_dragging_card()
				return
			dragging_card = card
			
			shop_ui.hide()
			sfx_draw.play()
	)
	return card

var state_animation : Tween = null
var state_player : Player
var state_animation_pos : Vector2
func on_state_animation(what, data):
	if what == "begin":
		state_animation = get_tree().create_tween()
		if Game.state == Game.PrepareState:
			state_animation.tween_interval(0.5)
		state_player = data
		return true
	elif what == "next_building":
		state_animation_pos = tilemap.map_to_local(data)
		state_animation.tween_interval(0.15)
		var pos = state_animation_pos
		state_animation.tween_callback(func():
			camera.move_to(tilemap.to_global(pos))
		)
		state_animation.tween_interval(0.2)
		return true
	elif what == "territory":
		state_animation.tween_callback(func():
			sfx_shuffle.play()
		)
		for i in data:
			var pos = state_animation_pos
			state_animation.tween_callback(func():
				var card = add_hand_card()
				card.setup("territory")
				var card_temp = CardBasePrefab.instantiate()
				Card.setup_from_data(card_temp, inst_to_dict(card))
				card_temp.position = tilemap.get_canvas_transform().origin + pos - Vector2(Game.card_hf_width, Game.card_hf_height)
				ui_root.add_child(card_temp)
				var tween2 = get_tree().create_tween()
				tween2.tween_property(card_temp, "position", hand.global_position + Vector2(hand.get_child_count() * 64, 0), 0.15)
				tween2.tween_callback(func():
					card_temp.queue_free()
					hand.add_child(card)
				)
				state_player.unused_territories += 1
			)
			state_animation.tween_interval(0.1)
		return true
	elif what == "production":
		var pos = state_animation_pos
		state_animation.tween_callback(func():
			add_resource(Game.ProductionResource, data, pos - Vector2(Game.card_hf_width, Game.card_hf_height), scene_root)
		)
		return true
	elif what == "gold":
		var pos = state_animation_pos
		state_animation.tween_callback(func():
			add_resource(Game.GoldResource, data, pos - Vector2(Game.card_hf_width, Game.card_hf_height), scene_root)
		)
		return true
	elif what == "science":
		var pos = state_animation_pos
		state_animation.tween_callback(func():
			add_resource(Game.ScienceResource, data, pos - Vector2(Game.card_hf_width, Game.card_hf_height), scene_root)
		)
		return true
	elif what == "food":
		var pos = state_animation_pos
		state_animation.tween_callback(func():
			add_resource(Game.FoodResource, data, pos - Vector2(Game.card_hf_width, Game.card_hf_height), scene_root)
		)
		return true
	elif what == "unit":
		state_animation.tween_callback(func():
			sfx_shuffle.play()
		)
		for i in data.unit_count:
			var pos = state_animation_pos
			state_animation.tween_callback(func():
				var card = add_hand_card()
				card.setup_unit_card(data.unit_name)
				var card_temp = CardBasePrefab.instantiate()
				Card.setup_from_data(card_temp, inst_to_dict(card))
				card_temp.position = tilemap.get_canvas_transform().origin + pos - Vector2(Game.card_hf_width, Game.card_hf_height)
				ui_root.add_child(card_temp)
				var tween2 = get_tree().create_tween()
				tween2.tween_property(card_temp, "position", hand.global_position + Vector2(hand.get_child_count() * 64, 0), 0.15)
				tween2.tween_callback(func():
					card_temp.queue_free()
					hand.add_child(card)
				)
				state_player.add_unit(data.unit_name)
			)
			state_animation.tween_interval(0.1)
		return true

func on_state_changed():
	if Game.state == Game.PrepareState:
		state_text.text = "准备阶段"
		tips_text.text = " 1、拖拽领地卡到临近的空地块上以扩充领地\n 2、拖拽建筑卡到领地上来添加建筑\n 3、从商店使用生产力或金币来购买建筑卡或领地卡"
		
		round_tip.modulate.a = 1
		round_tip.show()
		round_text.text = "回合%d" % Game.round
		if round_tip_tween != null:
			round_tip_tween.kill()
			round_tip_tween = null
		round_tip_tween = get_tree().create_tween()
		round_tip_tween.tween_interval(0.5)
		round_tip_tween.tween_property(round_tip, "modulate:a", 0, 0.3)
		round_tip_tween.tween_callback(func():
			round_tip.hide()
			round_tip_tween = null
		)
		
		shop_ui.hide()
		tech_ui.hide()
		state_animation.tween_callback(func():
			pass
			#shop_ui.show()
		)
	elif Game.state == Game.BattleState:
		state_text.text = "战斗阶段"
		tips_text.text = " 1、战斗时，参与的势力轮流对目标发起攻击，目标领地的领主作为防御方对攻击进行应对\n 2、点击单位卡以放置在军队栏上或从军队栏上返还\n 3、作为防御方时在军队栏上放置应对此次攻击的单位\n 4、作为攻击方时在军队栏上放置发起攻击的单位，并指定攻击目标\n 5、所有势力的单位使用完毕后战斗结束"
		
		shop_ui.hide()
		tech_ui.hide()
		state_animation.tween_callback(func():
			Game.next_attacker()
		)
			
func on_battle_player_changed():
	if Game.battle_attacker == Game.main_player_id:
		action_text.text = "你是攻击方"
	elif Game.battle_defender == Game.main_player_id:
		action_text.text = "你是防守方"
	elif Game.battle_attacker == -1:
		pass
	else:
		pass
	tilemap_overlay.queue_redraw()

func process_card_drop():
	if dragging_card.target_type == Card.TargetTile:
		if Game.hovering_tile.x != -1:
			var result = {}
			if dragging_card.activate_on_tile(Game.hovering_tile, result):
				if dragging_card.type == Card.TerritoryCard || dragging_card.type == Card.BuildingCard:
					sfx_build.play()
				dragging_card.queue_free()
				return true
			else:
				sfx_error.play()
				alert(result.message)
	return false

func release_dragging_card():
	if dragging_card == null:
		return
	dragging_card.release_drag()
	dragging_card = null
	
func _input(event: InputEvent) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if select_tile_callback.is_valid():
					select_tile_callback.call(Game.hovering_tile, false)
					select_tile_callback = Callable()
			else:
				if dragging_card:
					process_card_drop()
					dragging_card = null
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if select_tile_callback.is_valid():
					select_tile_callback.call(Vector2i(-1, -1), false)
					select_tile_callback = Callable()
	
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_H:
				camera.move_to(tilemap.to_global(tilemap.map_to_local(Game.main_player.coord)))
			elif event.keycode == KEY_S:
				on_shop_button()
			elif event.keycode == KEY_T:
				on_tech_button()

func add_shop_item(card_type : int, name : String, use_resource : int, cost : int, amount : int):
	var shop_item = ShopItemPrefab.instantiate()
	if card_type == Card.TerritoryCard:
		shop_item.setup_territory_item(use_resource, cost)
	elif card_type == Card.BuildingCard:
		shop_item.setup_building_item(name, use_resource)
	elif card_type == Card.UnitCard:
		shop_item.setup_unit_item(name, amount)
	shop_item.mouse_entered.connect(func():
		tooltip_using = true
		var info : Dictionary
		if card_type == Card.TerritoryCard:
			info = Card.get_info("territory")
		elif card_type == Card.BuildingCard:
			info = Building.get_info(name)
			info.description = "地块需求：%s\n" % Building.get_need_terrain_text(info.need_terrain) + info.description
		elif card_type == Card.UnitCard:
			info = Unit.get_info(name)
		var text = shop_item.display_name
		text += "\n%s" % info.description.format(info)
		tooltip_text.text = text
		tooltip.show()
		sfx_hover.play()
	)
	shop_item.mouse_exited.connect(func():
		tooltip_using = true
		tooltip.hide()
	)
	shop_item.clicked.connect(func():
		if shop_using:
			return
		var result = {}
		if shop_item.buy(result):
			shop_using = true
			add_resource(result.cost_type, -result.cost, shop_item.global_position)
			sfx_buy.play()
			
			var card_temp = CardBasePrefab.instantiate()
			Card.setup_from_data(card_temp, result.card_data)
			card_temp.position = shop_item.global_position
			ui_root.add_child(card_temp)
			var card_tween = get_tree().create_tween()
			card_tween.tween_property(card_temp, "position", hand.global_position + Vector2(hand.get_child_count() * 64, 0), 0.15)
			card_tween.tween_callback(func():
				card_temp.queue_free()
				var card = add_hand_card()
				if card_type == Card.TerritoryCard:
					card.setup("territory")
					Game.main_player.unused_territories += 1
				elif card_type == Card.BuildingCard:
					card.setup_building_card(name)
				elif card_type == Card.UnitCard:
					card.setup_unit_card(name)
					Game.main_player.add_unit(name)
				hand.add_child(card)
				shop_using = false
			)
		else:
			alert(result.message)
			sfx_error.play()
	)
	shop_list.add_child(shop_item)

func update_shop_list():
	for n in shop_list.get_children():
		shop_list.remove_child(n)
		n.queue_free()
	var category = shop_tab_bar.current_tab
	if category == 0:
		add_shop_item(Card.TerritoryCard, "", Game.ProductionResource, 20 + (Game.main_player.territories.size() + Game.main_player.unused_territories) * 2, -1)
		for k in Game.main_player.avaliable_constructions:
			add_shop_item(Card.BuildingCard, k, Game.ProductionResource, -1, -1)
	elif category == 1:
		for k in Game.main_player.avaliable_constructions:
			add_shop_item(Card.BuildingCard, k, Game.GoldResource, -1, -1)
	elif category == 2:
		for k in Game.main_player.avaliable_trainings:
			add_shop_item(Card.UnitCard, k.name, Game.GoldResource, -1, k.amount)

func on_shop_close_button() -> void:
	shop_ui.hide()
	sfx_close.play()

func on_shop_tab_changed(tab: int) -> void:
	update_shop_list()

func on_shop_button() -> void:
	if shop_ui.visible:
		shop_ui.hide()
		sfx_close.play()
	else:
		update_shop_list()
		shop_ui.show()
		tech_ui.hide()
		sfx_open.play()

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

func on_deconstruct_button(v : bool):
	if v:
		select_tile_callback = Callable(func(coord : Vector2i, is_peeding : bool):
			Game.main_player.troop_target = coord
			if !is_peeding:
				deconstruct_button.set_pressed_no_signal(false)
				deconstruct_button.toggled.emit(false)
				if coord.x != -1 && coord.y != -1:
					Game.main_player.remove_building(coord)
		)
	else:
		select_tile_callback = Callable()
		
var battle_animation : Tween = null
func on_battle_calc(what : String, data):
	if what == "init_fighting":
		for n in battle_list1.get_children():
			battle_list1.remove_child(n)
			n.queue_free()
		for n in battle_list2.get_children():
			battle_list2.remove_child(n)
			n.queue_free()
		var i = 0
		for u in data.attacker_units:
			var battle_unit = BattleUnitPrefab.instantiate()
			battle_unit.position.x = i * 54
			battle_unit.pivot_offset = Vector2(25, 30)
			battle_unit.find_child("TextureRect").texture = load(u.icon)
			battle_list1.add_child(battle_unit)
			i += 1
		i = 0
		for u in data.defender_units:
			var battle_unit = BattleUnitPrefab.instantiate()
			battle_unit.position.x = i * 54
			battle_unit.pivot_offset = Vector2(25, 30)
			battle_unit.find_child("TextureRect").texture = load(u.icon)
			battle_list2.add_child(battle_unit)
			i += 1
		battle_animation = get_tree().create_tween()
		return true
	elif what == "fighting_result":
		battle_list1.position.y = 27
		battle_list2.position.y = 137
		battle_animation.tween_callback(func():
			battle_ui.show()
		)
		battle_animation.tween_interval(0.3)
		battle_animation.tween_property(battle_list1, "position:y", 12, 0.2)
		battle_animation.parallel().tween_property(battle_list2, "position:y", 151, 0.2)
		battle_animation.tween_property(battle_list1, "position:y", 59, 0.2)
		battle_animation.parallel().tween_property(battle_list2, "position:y", 106, 0.2)
		
		battle_animation.tween_interval(0.3)
		for i in data.attacker_lost:
			var n = battle_list1.get_child(i)
			var rad = +1.0 if randf() > 0.5 else -1.0
			rad *= randf() * 10.0 + 5.0
			var x = randf() * 100.0 - 50.0
			var y = randf() * -50.0 - 50.0
			battle_animation.parallel().tween_property(n, "position", n.position + Vector2(x, y), 0.3)
			battle_animation.parallel().tween_property(n, "rotation", rad, 0.3)
			battle_animation.parallel().tween_property(n, "modulate:a", 0, 0.3)
		for i in data.defender_lost:
			var n = battle_list2.get_child(i)
			var rad = +1.0 if randf() > 0.5 else -1.0
			rad *= randf() * 10.0 + 5.0
			var x = randf() * 100.0 - 50.0
			var y = randf() * 50.0 + 50.0
			battle_animation.parallel().tween_property(n, "position", n.position + Vector2(x, y), 0.3)
			battle_animation.parallel().tween_property(n, "rotation", rad, 0.3)
			battle_animation.parallel().tween_property(n, "modulate:a", 0, 0.3)
		return true
	elif what == "fighting_end":
		battle_animation.tween_interval(0.2)
		battle_animation.tween_callback(func():
			battle_ui.hide()
			Game.next_attacker()
		)
		return true
	elif what == "production":
		if Game.battle_attacker == Game.main_player_id:
			battle_animation.tween_callback(func():
				add_resource(Game.ProductionResource, data.value, tilemap.map_to_local(data.coord), scene_root)
			)
			return true
		return false
	elif what == "gold":
		if Game.battle_attacker == Game.main_player_id:
			battle_animation.tween_callback(func():
				add_resource(Game.GoldResource, data.value, tilemap.map_to_local(data.coord), scene_root)
			)
			return true
		return false
	elif what == "science":
		if Game.battle_attacker == Game.main_player_id:
			battle_animation.tween_callback(func():
				add_resource(Game.ScienceResource, data.value, tilemap.map_to_local(data.coord), scene_root)
			)
			return true
		return false
	elif what == "food":
		if Game.battle_attacker == Game.main_player_id:
			battle_animation.tween_callback(func():
				add_resource(Game.FoodResource, data.value, tilemap.map_to_local(data.coord), scene_root)
			)
			return true
		return false

func on_attack_commited():
	var attacker_player = Game.players[Game.battle_attacker]
	var path = attacker_player.troop_path
	var target_pos = tilemap.get_canvas_transform().origin + tilemap.map_to_local(path[0 if Game.battle_attacker == Game.main_player_id else path.size() - 1].coord)
	var tween = get_tree().create_tween()
	for card in hand.get_children():
		if card.selected:
			if card.tween:
				card.tween.kill()
			card.modulate.a = 0
			card.tween = get_tree().create_tween()
			card.tween.tween_property(card, "custom_minimum_size:x", 0, 0.15)
			card.tween.tween_callback(func():
				card.queue_free()
				tilemap_overlay.queue_redraw()
			)
			var card_shadow = CardShadowPrefab.instantiate()
			var start_pos = hand.global_position + card.position
			ui_root.add_child(card_shadow)
			var tween2 = get_tree().create_tween()
			tween2.tween_method(func(t : float):
				var pts = []
				if t < 0.5:
					pts.append(lerp(start_pos, target_pos, t * 2))
					pts.append(lerp(start_pos + Vector2(Game.card_width, 0), target_pos, t * 2))
					pts.append(start_pos + Vector2(Game.card_width, Game.card_height))
					pts.append(start_pos + Vector2(0, Game.card_height))
				else:
					pts.append(target_pos)
					pts.append(target_pos)
					pts.append(lerp(start_pos + Vector2(Game.card_width, Game.card_height), target_pos, (t - 0.5) * 2))
					pts.append(lerp(start_pos + Vector2(0, Game.card_height), target_pos, (t - 0.5) * 2))
				card_shadow.polygon = pts
			, 0.0, 1.0, 0.35)
			tween2.tween_callback(func():
				card_shadow.queue_free()
			)
			
	attack_troop_mark.show()
	attack_troop_mark.position = tilemap.to_global(tilemap.map_to_local(attacker_player.troop_path[0].coord))
	attack_troop_mark.modulate = attacker_player.color
	attack_troop_mark.modulate.a = 0
	tween.tween_interval(0.5)
	var focus_coord = attacker_player.troop_path[attacker_player.troop_path.size() / 2].coord
	tween.tween_callback(func():
		camera.move_to(tilemap.to_global(tilemap.map_to_local(focus_coord)))
	)
	tween.tween_property(attack_troop_mark, "modulate:a", 1.0, 0.15)
	var has_resistance = Game.battle_defender != -1
	if has_resistance:
		var defender_player = Game.players[Game.battle_defender]
		has_resistance = !defender_player.troop_units.is_empty()
	var num = attacker_player.troop_path.size()
	if num >= 2:
		var t = 0.4 / (num - 1)
		for i in num - 1:
			var pos = tilemap.to_global(tilemap.map_to_local(attacker_player.troop_path[i + 1].coord))
			if i == num - 2 && has_resistance:
				pos = (pos + tilemap.to_global(tilemap.map_to_local(attacker_player.troop_path[i].coord))) * 0.5
			tween.tween_property(attack_troop_mark, "position", pos, t)
	tween.tween_callback(func():
		attack_troop_mark.hide()
		if Game.battle_attacker == Game.main_player_id || Game.battle_defender == Game.main_player_id:
			Game.battle_calc_callback = Callable(on_battle_calc)
		Game.battle_calc()
		if Game.battle_calc_callback.is_valid():
			Game.battle_calc_callback = Callable()
		tilemap_overlay.queue_redraw()
	)
	tilemap_overlay.queue_redraw()

func on_comfire_button():
	if Game.state == Game.PrepareState:
		Game.change_state(Game.BattleState)
	elif Game.state == Game.BattleState:
		if Game.battle_attacker == Game.main_player_id:
			if Game.main_player.troop_target.x == -1 || Game.main_player.troop_target.y == -1:
				alert("需要指定一个目标")
				sfx_error.play()
			elif Game.main_player.troop_units.is_empty():
				alert("需要至少一个单位")
				sfx_error.play()
			elif Game.main_player.troop_mobility + 1 < Game.main_player.troop_path.size():
				alert("行军距离不够")
				sfx_error.play()
			else:
				action_text.text = ""
				Game.commit_attack()
		elif Game.battle_defender == Game.main_player_id:
			Game.commit_attack()

func on_cancel_button():
	if Game.state == Game.BattleState:
		if Game.battle_attacker == Game.main_player_id:
			yes_no_dialog("是否跳过攻击？", func(yes : bool):
				if yes:
					Game.skip_attack()
			)
		else:
			Game.commit_attack()

func on_show_tip_button():
	if tips_text.visible:
		tips_text.hide()
		show_tips_button.text = "显示"
	else:
		tips_text.show()
		show_tips_button.text = "隐藏"
	
func init_tiles():
	var water_tiles = {}
	var grass_tiles = {}
	var forest_tiles = {}
	for c in Game.map:
		var tile = Game.map[c] as Tile
		if tile.terrain == Tile.TerrainWater:
			water_tiles[c] = 1
		elif tile.terrain == Tile.TerrainPlain:
			grass_tiles[c] = 1
		elif tile.terrain == Tile.TerrainForest:
			grass_tiles[c] = 1
			forest_tiles[c] = 1
	if !water_tiles.is_empty():
		tilemap_water.set_cells_terrain_connect(water_tiles.keys(), 0, 0, false)
		var bank_tiles = {}
		for c in water_tiles:
			var t = Game.map[c]
			for _t in Game.get_surrounding_tiles(t):
				var k = _t.coord
				if !bank_tiles.has(k) && !water_tiles.has(k):
					bank_tiles[k] = 1
		if !bank_tiles.is_empty():
			tilemap_dirt.set_cells_terrain_connect(bank_tiles.keys(), 0, 0, false)
	if !grass_tiles.is_empty():
		tilemap.set_cells_terrain_connect(grass_tiles.keys(), 0, 0, false)
	if !forest_tiles.is_empty():
		for c in forest_tiles:
			tilemap_object.set_cell(c, 1, Vector2i(0, 0))
	
	for x in range(-1, Game.cx + 1):
		for y in range(-1, Game.cy + 1):
			var c = Vector2i(x, y)
			if x >= 0 && x < Game.cx && y >= 0 && y < Game.cy:
				var tile = Game.map[c] as Tile
				tile.tilemap_atlas_ids.append(tilemap_water.get_cell_source_id(c))
				tile.tilemap_atlas_ids.append(tilemap_dirt.get_cell_source_id(c))
				tile.tilemap_atlas_ids.append(tilemap.get_cell_source_id(c))
				tile.tilemap_atlas_ids.append(tilemap_object.get_cell_source_id(c))
				tile.tilemap_atlas_coords.append(tilemap_water.get_cell_atlas_coords(c))
				tile.tilemap_atlas_coords.append(tilemap_dirt.get_cell_atlas_coords(c))
				tile.tilemap_atlas_coords.append(tilemap.get_cell_atlas_coords(c))
				tile.tilemap_atlas_coords.append(tilemap_object.get_cell_atlas_coords(c))
			tilemap_water.set_cell(c, -1)
			tilemap_dirt.set_cell(c, -1)
			tilemap.set_cell(c, -1)
			tilemap_object.set_cell(c, -1)
			
	update_tiles()

var updated_tiles = {}

func update_tiles():
	for x in Game.cx:
		for y in Game.cy:
			var c = Vector2i(x, y)
			var tile = Game.map[c] as Tile
			if !updated_tiles.has(c) && Game.main_player.vision.has(c):
				tilemap_water.set_cell(c, tile.tilemap_atlas_ids[0], tile.tilemap_atlas_coords[0])
				tilemap_dirt.set_cell(c, tile.tilemap_atlas_ids[1], tile.tilemap_atlas_coords[1])
				tilemap.set_cell(c, tile.tilemap_atlas_ids[2], tile.tilemap_atlas_coords[2])
				tilemap_object.set_cell(c, tile.tilemap_atlas_ids[3], tile.tilemap_atlas_coords[3])
				updated_tiles[c] = 1
				
func update_buildings(id : int):
	var player = Game.players[id] as Player
	for c in player.territories:
		updated_tiles.erase(c)
	update_tiles()
	for c in player.buildings:
		if Game.main_player.vision.has(c):
			var building = player.buildings[c]
			tilemap_object.set_cell(c, building.image_tile_id, Vector2i(0, 0))

func overlay_drawer(node : Node2D):
	if Game.battle_attacker != -1:
		var attacker_player = Game.players[Game.battle_attacker] as Player
		var num = attacker_player.troop_path.size()
		if num > 0:
			var has_resistance = Game.battle_defender != -1
			if has_resistance:
				var defender_player = Game.players[Game.battle_defender] as Player
				has_resistance = !defender_player.troop_units.is_empty()
			for i in num - 1:
				var color = attacker_player.color if attacker_player.troop_mobility >= i + 1 else Color(0.5, 0.5, 0.5, 1)
				var p0 = tilemap.map_to_local(attacker_player.troop_path[i].coord)
				var p1 = tilemap.map_to_local(attacker_player.troop_path[i + 1].coord)
				if i == num - 2 && has_resistance:
					p1 = (p0 + p1) * 0.5
				node.draw_dashed_line(p0, p1, color, 6, 14)
			if num >= 2:
				var p0 = tilemap.map_to_local(attacker_player.troop_path[num - 2].coord)
				var p1 = tilemap.map_to_local(attacker_player.troop_path[num - 1].coord)
				if has_resistance:
					p1 = (p0 + p1) * 0.5
				var head = (p0 - p1).normalized() * 30
				var color = attacker_player.color if attacker_player.troop_mobility >= num - 1 else Color(0.5, 0.5, 0.5, 1)
				node.draw_line(p1, p1 + head.rotated(+0.4), color, 6)
				node.draw_line(p1, p1 + head.rotated(-0.4), color, 6)
				if has_resistance:
					var p2 = tilemap.map_to_local(attacker_player.troop_path[num - 1].coord)
					var p3 = tilemap.map_to_local(attacker_player.troop_path[num - 2].coord)
					p3 = (p2 + p3) * 0.5
					var head2 = (p2 - p3).normalized() * 30
					var defender_player = Game.players[Game.battle_defender] as Player
					node.draw_line(p3, p3 + head2.rotated(+0.4), defender_player.color, 6)
					node.draw_line(p3, p3 + head2.rotated(-0.4), defender_player.color, 6)

func _ready() -> void:
	init_tiles()
	for id in Game.players:
		update_buildings(id)
			
	tilemap.tile_hovered.connect(func(coord : Vector2i):
		if select_tile_callback.is_valid():
			select_tile_callback.call(coord, true)
			
		if !tooltip_using:
			if coord.x == -1 && coord.y == -1:
				tooltip.hide()
			else:
				var t = Game.map[coord] as Tile
				var text = "[font_size=18]%s[/font_size]" % Tile.get_terrain_text(t.terrain)
				var dic = t.get_neutral_unit_types()
				for k in dic:
					var info = Unit.get_info(k)
					text += "\n[img=20]%s[/img] x%d" % [info.icon, dic[k]]
				if t.resource_amount > 0:
					text += "\n资源: %d[img=20]%s[/img]" % [t.resource_amount, Game.get_resource_icon(t.resource_type)]
				if t.player != -1:
					var player = Game.players[t.player] as Player
					text += "\n领地归属: %d" % player.id
				else:
					text += "\n领地归属: 无"
				if t.building != "":
					var player = Game.players[t.player] as Player
					var building = player.buildings[t.coord]
					text += "\n------------------------"
					text += "\n%s" % building.display_name
					text += "\n%s" % building.description.format(building.ext)
				else:
					text += "\n建筑: 无"
				tooltip_text.text = text
				tooltip.show()
		tooltip_using = false
	)
	camera.position = tilemap.map_to_local(tilemap.get_used_rect().get_center())
	
	tilemap_overlay.drawer = overlay_drawer
	
	for id in Game.players:
		var player = Game.players[id] as Player
		player.territory_changed.connect(tilemap_overlay.update_border)
		player.building_changed.connect(func(id):
			update_buildings(id)
			queue_redraw()
		)
		tilemap_overlay.update_border(id)
	
	Game.main_player.on_state_callback = Callable(on_state_animation)
	Game.main_player.vision_changed.connect(update_tiles)
	
	update_production(0, Game.main_player.production)
	update_gold(0, Game.main_player.gold)
	update_science(0, Game.main_player.science)
	update_food(0, Game.main_player.food)
	Game.main_player.production_changed.connect(update_production)
	Game.main_player.gold_changed.connect(update_gold)
	Game.main_player.science_changed.connect(update_science)
	Game.main_player.food_changed.connect(update_food)
		
	Game.state_changed.connect(on_state_changed)
	Game.battle_player_changed.connect(on_battle_player_changed)
	Game.attack_commited.connect(on_attack_commited)
		
	for n in hand.get_children():
		hand.remove_child(n)
		n.queue_free()
		
	for n in Game.techs:
		var t = Game.techs[n]
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
			
			sfx_hover.play()
		)
		tech_item.mouse_exited.connect(func():
			tooltip_using = true
			tooltip.hide()
		)
		tech_item.clicked.connect(func():
			if Game.main_player.science >= t.cost_science && t.level < t.max_level:
				add_resource(Game.ScienceResource, -t.cost_science, tech_item.global_position)
				
				t.acquired(Game.main_player)
				
				tech_item.get_node("Label").text = "%d/%d" % [t.level, t.max_level]
				tech_item.hide()
				tech_item.show()
		)
		tech_tree.add_child(tech_item)
	
	shop_ui.hide()
	tech_ui.hide()
	
	for c in Game.loaded_hand_data:
		if c.type == Card.NormalCard:
			pass
		elif c.type == Card.TerritoryCard:
			var card = add_hand_card()
			card.setup("territory")
			hand.add_child(card)
		elif c.type == Card.BuildingCard:
			var card = add_hand_card()
			card.setup_building_card(c.name.substr(0, c.name.length() - 9))
			hand.add_child(card)
			pass
		elif c.type == Card.UnitCard:
			var card = add_hand_card()
			card.setup_unit_card(c.name.substr(0, c.name.length() - 5))
			hand.add_child(card)
			pass
	Game.loaded_hand_data.clear()
	Game.on_scene_ready()

func on_game_menu() -> void:
	if get_tree().get_processed_tweens().is_empty():
		$CanvasLayer/GameMenu.show()
		sfx_open.play()

func on_resume() -> void:
	$CanvasLayer/GameMenu.hide()
	sfx_open.play()

func on_save_game() -> void:
	var hand_data = []
	for n in hand.get_children():
		var c = {}
		c.type = n.type
		c.name = n.card_name
		hand_data.append(c)
	Game.save_game("res://savings/auto_save.txt", hand_data)

func on_load_game() -> void:
	Game.load_game("res://savings/auto_save.txt")
	get_tree().reload_current_scene()

func on_back_to_title() -> void:
	get_tree().change_scene_to_file("res://title_screen.tscn")

func on_quit() -> void:
	get_tree().quit()
