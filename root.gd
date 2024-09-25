extends Node2D

const Tile = preload("res://tile.gd")
const Player = preload("res://player.gd")
const Camera = preload("res://camera.gd")
const Tilemap = preload("res://tilemap.gd")
const TilemapOverlay = preload("res://tilemap_overlay.gd")
const CardBasePrefab = preload("res://card_base.tscn")
const CardPrefab = preload("res://card_ui.tscn")
const ShopItemPrefab = preload("res://shop_item_ui.tscn")

var tilemap : Tilemap
var tilemap_overlay : TilemapOverlay
var camera : Camera
var ui_root : CanvasLayer
var state_text : Label
var tips_text : Label
var state_button : Button
var resource_panel : Control
var production_text : Label
var production_text_tween : Tween = null
var hand : HBoxContainer
var dragging_card : Card = null
var drag_offset : Vector2
var dragging_dummy : Control
var dragging_dummy_tween : Tween = null
var shop_ui : Control
var shop_list : GridContainer
var troop_ui : Control
var troop_list : HBoxContainer
var troop_side_text : Label
var troop_target_button : CheckButton
var troop_comfire_button : Button
var attack_troop_mark : Polygon2D
var defend_troop_mark : Polygon2D
var battle_ui : Control
var battle_list1 : Control
var battle_list2 : Control
var tooltip : Control
var tooltip_text : Label
var tooltip_using = false

var select_tile_callback : Callable

func alert(text: String, callback : Callable):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	dialog.title = "Message"
	dialog.get_ok_button().hide()
	var scene_tree = Engine.get_main_loop()
	scene_tree.current_scene.add_child(dialog)
	dialog.canceled.connect(func():
		if callback.is_valid():
			callback.call()
		dialog.queue_free()
	)
	dialog.popup_centered()
	return dialog

func update_tilemap():
	for x in Game.cx:
		for y in Game.cy:
			tilemap.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
			
func add_production(v : int, pos : Vector2):
	var text_temp = Label.new()
	if v > 0:
		text_temp.text = "+%dP" % v
		text_temp.add_theme_color_override("font_color", Color.GREEN)
	else:
		text_temp.text = "-%dP" % v
		text_temp.add_theme_color_override("font_color", Color.RED)
	text_temp.position = pos
	ui_root.add_child(text_temp)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(text_temp, "position", pos - Vector2(0, 5), 0.2)
	tween2.tween_callback(func():
		var main_player = Game.players[0] as Player
		main_player.add_production(v)
	)
	tween2.tween_property(text_temp, "position", pos - Vector2(0, 10), 0.2)
	tween2.tween_callback(func():
		text_temp.queue_free()
	)
			
func create_hand_card():
	var card = CardPrefab.instantiate()
	card.mouse_entered.connect(func():
		tooltip_using = true
		var text = "%s(卡)" % card.display_name
		text += "\n%s" % card.description
		tooltip_text.text = text
		tooltip.show()
	)
	card.mouse_exited.connect(func():
		tooltip_using = true
		tooltip.hide()
	)
	card.clicked.connect(func(_drag_offset : Vector2):
		if card.target_type == Card.TargetNull:
			pass
		elif card.target_type == Card.TargetTroop:
			if !card.tween:
				card.modulate.a = 0
				card.tween = get_tree().create_tween()
				card.tween.tween_property(card, "custom_minimum_size:x", 0, 0.15)
			
				var card_temp = CardBasePrefab.instantiate()
				card_temp.position = card.global_position
				card_temp.get_node("Name").text = card.display_name
				ui_root.add_child(card_temp)
				var card_tween = get_tree().create_tween()
				card_tween.tween_property(card_temp, "position", troop_list.global_position + Vector2(troop_list.get_child_count() * 50, 0), 0.15)
				card_tween.tween_callback(func():
					card_temp.queue_free()
					var new_card = CardPrefab.instantiate()
					new_card.copy(card)
					new_card.clicked.connect(func(_drag_offset : Vector2):
						if !new_card.tween:
							new_card.modulate.a = 0
							new_card.tween = get_tree().create_tween()
							new_card.tween.tween_property(new_card, "custom_minimum_size:x", 0, 0.15)
						
							var card_temp2 = CardBasePrefab.instantiate()
							card_temp2.position = new_card.global_position
							card_temp2.get_node("Name").text = new_card.display_name
							ui_root.add_child(card_temp2)
							var card_tween2 = get_tree().create_tween()
							card_tween2.tween_property(card_temp2, "position", hand.global_position + Vector2(hand.get_child_count() * 50, 0), 0.15)
							card_tween2.tween_callback(func():
								card_temp2.queue_free()
								var new_card2 = create_hand_card()
								new_card2.copy(new_card)
								hand.add_child(new_card2)
								new_card.queue_free()
								var main_player = Game.players[0] as Player
								main_player.move_unit_from_troop(new_card2.card_name.substr(0, new_card2.card_name.length() - 5))
								tilemap_overlay.queue_redraw()
							)
					)
					troop_list.add_child(new_card)
					card.queue_free()
					var main_player = Game.players[0] as Player
					main_player.move_unit_to_troop(new_card.card_name.substr(0, new_card.card_name.length() - 5))
					tilemap_overlay.queue_redraw()
				)
		else:
			dragging_card = card
			drag_offset = _drag_offset
			if card.tween:
				card.tween.kill()
			card.modulate.a = 0
			card.tween = get_tree().create_tween()
			card.tween.tween_property(card, "custom_minimum_size:x", 0, 0.15)
			card.tween.tween_callback(func():
				card.hide()
				card.tween = null
			)
		
			dragging_dummy.show()
			dragging_dummy.position = get_viewport().get_mouse_position() - drag_offset
			dragging_dummy.scale = Vector2(1, 1)
			dragging_dummy.find_child("Name").text = dragging_card.find_child("Name").text
			
			if dragging_dummy_tween:
				dragging_dummy_tween.kill()
			dragging_dummy_tween = get_tree().create_tween()
			dragging_dummy_tween.tween_property(dragging_dummy, "scale", Vector2(0.9, 0.9), 0.15)
			dragging_dummy_tween.tween_callback(func():
				dragging_dummy_tween = null
			)
			
			shop_ui.hide()
	)
	return card
	
var state_animation : Tween = null
var state_animation_player : Player
var state_animation_pos : Vector2
func on_state_animation(what, data):
	if what == "begin":
		state_animation = get_tree().create_tween()
		state_animation_player = data
	elif what == "next_building":
		state_animation_pos = tilemap.map_to_local(data)
		state_animation.tween_interval(0.15)
		var pos = state_animation_pos
		state_animation.tween_callback(func():
			camera.move_to(tilemap.to_global(pos))
		)
		state_animation.tween_interval(0.2)
	elif what == "territory":
		for i in data:
			var pos = state_animation_pos
			state_animation.tween_callback(func():
				var card = create_hand_card()
				card.setup("territory")
				var card_temp = CardBasePrefab.instantiate()
				card_temp.position = tilemap.get_canvas_transform().origin + pos - Vector2(25, 30)
				card_temp.get_node("Name").text = card.display_name
				ui_root.add_child(card_temp)
				var tween2 = get_tree().create_tween()
				tween2.tween_property(card_temp, "position", hand.global_position + Vector2(hand.get_child_count() * 50, 0), 0.15)
				tween2.tween_callback(func():
					card_temp.queue_free()
					hand.add_child(card)
				)
				state_animation_player.unused_territories += 1
			)
			state_animation.tween_interval(0.1)
	elif what == "production":
		var pos = state_animation_pos
		state_animation.tween_callback(func():
			add_production(data, tilemap.get_canvas_transform().origin + pos - Vector2(25, 30))
		)
	elif what == "unit":
		for i in data.unit_count:
			var pos = state_animation_pos
			state_animation.tween_callback(func():
				var card = create_hand_card()
				card.setup_unit_card(data.unit_name)
				var card_temp = CardBasePrefab.instantiate()
				card_temp.position = tilemap.get_canvas_transform().origin + pos - Vector2(25, 30)
				card_temp.get_node("Name").text = card.display_name
				ui_root.add_child(card_temp)
				var tween2 = get_tree().create_tween()
				tween2.tween_property(card_temp, "position", hand.global_position + Vector2(hand.get_child_count() * 50, 0), 0.15)
				tween2.tween_callback(func():
					card_temp.queue_free()
					hand.add_child(card)
				)
				state_animation_player.units.append(data.unit_name)
			)
			state_animation.tween_interval(0.1)

func on_state_changed():
	var main_player = Game.players[0] as Player
	
	if Game.state == Game.StatePrepare:
		state_text.text = "准备阶段"
		state_button.text = "开始战斗"
		tips_text.text = " 1、拖拽领地卡到临近的空地块上以扩充领地\n 2、拖拽建筑卡到领地上来添加此建筑\n 3、从商店使用生产力或金币来购买建筑卡或领地卡"
		
		shop_ui.hide()
		troop_ui.hide()
		state_animation.tween_callback(func():
			pass
			#shop_ui.show()
		)
		
		for n in shop_list.get_children():
			shop_list.remove_child(n)
			n.queue_free()
		for k in main_player.avaliable_constructions:
			var shop_item = ShopItemPrefab.instantiate()
			shop_item.setup_building_item(k)
			shop_item.mouse_entered.connect(func():
				tooltip_using = true
				var info = Building.get_info(k)
				var text = "%s" % shop_item.display_name
				text += "\n%s" % info.description.format(info)
				tooltip_text.text = text
				tooltip.show()
			)
			shop_item.mouse_exited.connect(func():
				tooltip_using = true
				tooltip.hide()
			)
			shop_item.clicked.connect(func():
				if main_player.production >= shop_item.cost_production:
					add_production(-shop_item.cost_production, shop_item.global_position)
					
					var card_temp = CardBasePrefab.instantiate()
					card_temp.position = shop_item.global_position
					card_temp.get_node("Name").text = shop_item.display_name
					ui_root.add_child(card_temp)
					var card_tween = get_tree().create_tween()
					card_tween.tween_property(card_temp, "position", hand.global_position + Vector2(hand.get_child_count() * 50, 0), 0.15)
					card_tween.tween_callback(func():
						card_temp.queue_free()
						var card = create_hand_card()
						card.setup_building_card(k)
						hand.add_child(card)
					)
			)
			shop_list.add_child(shop_item)
	elif Game.state == Game.StateBattle:
		state_text.text = "战斗阶段"
		state_button.text = "结束战斗"
		tips_text.text = " 1、战斗时，参与的势力轮流对目标发起攻击，目标领地的领主作为防御方对攻击进行应对\n 2、点击单位卡以放置在军队栏上或从军队栏上返还\n 3、作为防御方时在军队栏上放置应对此次攻击的单位\n 4、作为攻击方时在军队栏上放置发起攻击的单位，并指定攻击目标\n 5、所有势力的单位使用完毕后战斗结束"
		
		shop_ui.hide()
		troop_ui.hide()
		state_animation.tween_callback(func():
			troop_ui.show()
			
			Game.next_attacker()
		)
		for n in troop_list.get_children():
			troop_list.remove_child(n)
			n.queue_free()
			
func on_battle_player_changed():
	if Game.battle_attacker == 0:
		troop_side_text.text = "你是攻击方"
		troop_target_button.show()
		troop_ui.show()
	elif Game.battle_defender == 0:
		troop_side_text.text = "你是防守方"
		troop_target_button.hide()
		troop_ui.show()
	elif Game.battle_attacker == -1 :
		troop_ui.hide()
		var dialog = alert("没有可用的单位，战斗结束", func():
			Game.change_state(Game.StatePrepare)
		)
	else:
		troop_ui.hide()
	tilemap_overlay.queue_redraw()

func process_card_drop():
	if dragging_card.target_type == Card.TargetTile:
		if Game.hovering_tile.x != -1:
			if dragging_card.activate_on_tile(Game.hovering_tile):
				dragging_card.queue_free()
				return true
	return false

func move_back_drag_card():
	var tween = get_tree().create_tween()
	tween.tween_property(dragging_dummy, "position", dragging_card.global_position - Vector2(25, 0), 0.15)
	tween.tween_callback(func():
		dragging_dummy.hide()
	)
	
	var card = dragging_card
	card.show()
	if card.tween:
		card.tween.kill()
	card.tween = get_tree().create_tween()
	card.tween.tween_property(card, "custom_minimum_size:x", 50, 0.15)
	card.tween.tween_callback(func():
		card.modulate.a = 1
		card.tween = null
	)
	dragging_card = null
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		tilemap.set_hovering_tile(Vector2i(-1, -1))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if select_tile_callback.is_valid():
					select_tile_callback.call(Game.hovering_tile, false)
					select_tile_callback = Callable()
			else:
				if dragging_card:
					if process_card_drop():
						dragging_dummy.hide()
						dragging_card = null
					else:
						move_back_drag_card()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if dragging_card:
					move_back_drag_card()
				if select_tile_callback.is_valid():
					select_tile_callback.call(Vector2i(-1, -1), false)
					select_tile_callback = Callable()
	if event is InputEventMouseMotion:
		if dragging_card:
			dragging_dummy.position = event.position - drag_offset
	
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_H:
				var main_player = Game.players[0] as Player
				camera.move_to(tilemap.to_global(tilemap.map_to_local(main_player.coord)))
			elif event.keycode == KEY_S:
				if !shop_ui.visible:
					shop_ui.show()
				else:
					shop_ui.hide()

func on_shop_close_button() -> void:
	shop_ui.hide()

func on_shop_button() -> void:
	if shop_ui.visible:
		shop_ui.hide()
	else:
		shop_ui.show()

func on_target_button(v: bool) -> void:
	if v:
		select_tile_callback = Callable(func(coord : Vector2i, is_peeding : bool):
			var main_player = Game.players[0] as Player
			main_player.troop_target = coord
			if !is_peeding:
				troop_target_button.set_pressed_no_signal(false)
				troop_target_button.toggled.emit(false)
				if coord.x == -1 && coord.y == -1:
					main_player.troop_path.clear()
					tilemap_overlay.queue_redraw()
			else:
				if coord.x != -1 && coord.y != -1:
					var shortest_path = []
					var shortest_dist = 1000
					for c in main_player.territories:
						var path = Game.find_path_on_map(c, coord)
						if path.size() < shortest_dist:
							shortest_dist = path.size()
							shortest_path = path
					main_player.troop_path = shortest_path
					tilemap_overlay.queue_redraw()
				else:
					main_player.troop_path.clear()
					tilemap_overlay.queue_redraw()
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
			var card = CardBasePrefab.instantiate()
			card.position.x = i * 54
			card.pivot_offset = Vector2(25, 30)
			card.get_node("Name").text = u.display_name
			battle_list1.add_child(card)
			i += 1
		i = 0
		for u in data.defender_units:
			var card = CardBasePrefab.instantiate()
			card.position.x = i * 54
			card.pivot_offset = Vector2(25, 30)
			card.get_node("Name").text = u.display_name
			battle_list2.add_child(card)
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
		if Game.battle_attacker == 0:
			battle_animation.tween_callback(func():
				var main_player = Game.players[0] as Player
				add_production(data.value, tilemap.get_canvas_transform().origin + tilemap.map_to_local(data.coord))
			)
			return true
		return false

func on_troop_comfire() -> void:
	var main_player = Game.players[0] as Player
	if Game.battle_attacker == 0:
		if main_player.troop_target.x == -1 || main_player.troop_target.y == -1:
			alert("需要一个目标", Callable())
		elif main_player.troop_units.is_empty():
			alert("需要至少一个单位", Callable())
		elif main_player.troop_mobility + 1 < main_player.troop_path.size():
			alert("行军距离不够", Callable())
		else:
			troop_side_text.text = ""
			troop_target_button.disabled = true
			for n in troop_list.get_children():
				troop_list.remove_child(n)
				n.queue_free()
			troop_ui.hide()
			Game.commit_attack()
	elif Game.battle_defender == 0:
		Game.commit_attack()

func on_attack_commited():
	var attacker_player = Game.players[Game.battle_attacker] as Player
	var focus_coord = attacker_player.troop_path[attacker_player.troop_path.size() / 2].coord
	camera.move_to(tilemap.to_global(tilemap.map_to_local(focus_coord)))
	var tween = get_tree().create_tween()
	var num = attacker_player.troop_path.size()
	attack_troop_mark.show()
	attack_troop_mark.position = tilemap.to_global(tilemap.map_to_local(attacker_player.troop_path[0].coord))
	attack_troop_mark.modulate = attacker_player.color
	attack_troop_mark.modulate.a = 0
	tween.tween_property(attack_troop_mark, "modulate:a", 1.0, 0.15)
	var has_resistance = Game.battle_defender != -1
	if has_resistance:
		var defender_player = Game.players[Game.battle_defender] as Player
		has_resistance = !defender_player.troop_units.is_empty()
	if num >= 2:
		var t = 0.4 / (num - 1)
		for i in num - 1:
			var pos = tilemap.to_global(tilemap.map_to_local(attacker_player.troop_path[i + 1].coord))
			if i == num - 2 && has_resistance:
				pos = (pos + tilemap.to_global(tilemap.map_to_local(attacker_player.troop_path[i].coord))) * 0.5
			tween.tween_property(attack_troop_mark, "position", pos, t)
	tween.tween_callback(func():
		attack_troop_mark.hide()
		if Game.battle_attacker == 0 || Game.battle_defender == 0:
			Game.battle_calc_callback = Callable(on_battle_calc)
		Game.battle_calc()
		if Game.battle_calc_callback.is_valid():
			Game.battle_calc_callback = Callable()
		tilemap_overlay.queue_redraw()
	)
	tilemap_overlay.queue_redraw()

func on_state_button() -> void:
	if Game.state == Game.StatePrepare:
		Game.change_state(Game.StateBattle)
	elif Game.state == Game.StateBattle:
		if Game.is_battle_round_ended():
			Game.change_state(Game.StatePrepare)
		else:
			alert("还有未使用的单位", Callable())

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
	tilemap = $TileMapLayer
	tilemap_overlay = $TileMapOverlay
	camera = $Camera2D
	ui_root = $CanvasLayer
	state_text = $CanvasLayer/PanelContainer/VBoxContainer/Label
	tips_text = $CanvasLayer/PanelContainer/VBoxContainer/Label2
	state_button = $CanvasLayer/MarginContainer/HBoxContainer/StateButton
	resource_panel = $CanvasLayer/ResourcePanel
	production_text = $CanvasLayer/ResourcePanel/Label
	hand = $CanvasLayer/MarginContainer2/Hand
	dragging_dummy = $CanvasLayer/DragCard
	shop_ui = $CanvasLayer/Shop
	shop_list = $CanvasLayer/Shop/VBoxContainer/GridContainer
	troop_ui = $CanvasLayer/MarginContainer3/Troop
	troop_list = $CanvasLayer/MarginContainer3/Troop/VBoxContainer/HBoxContainer/HBoxContainer
	troop_side_text = $CanvasLayer/MarginContainer3/Troop/SideText
	troop_target_button = $CanvasLayer/MarginContainer3/Troop/VBoxContainer/HBoxContainer/TargetButton
	troop_comfire_button = $CanvasLayer/MarginContainer3/Troop/VBoxContainer/HBoxContainer/ComfireButton
	attack_troop_mark = $AttackTroop
	defend_troop_mark = $DefendTroop
	battle_ui = $CanvasLayer/Battle
	battle_list1 = $CanvasLayer/Battle/Control/Side1
	battle_list2 = $CanvasLayer/Battle/Control/Side2
	tooltip = $CanvasLayer/ToolTip
	tooltip_text = $CanvasLayer/ToolTip/VBoxContainer/Text
	
	update_tilemap()
	tilemap.tile_hovered.connect(func(coord : Vector2i):
		if select_tile_callback.is_valid():
			select_tile_callback.call(coord, true)
			
		if !tooltip_using:
			if coord.x == -1 && coord.y == -1:
				tooltip.hide()
			else:
				var t = Game.map[coord] as Tile
				if t.player == -1:
					var text = "平原"
					var dic = {}
					for u in t.neutral_units:
						if dic.has(u):
							dic[u] += 1
						else:
							dic[u] = 1
					for k in dic:
						var info = Unit.get_info(k)
						text += "\n%s x%d" % [info.display_name, dic[k]]
					text += "\n%dP" % t.production_resource
					tooltip_text.text = text
				else:
					var player = Game.players[t.player] as Player
					tooltip_text.text = "%d 的领地" % player.id
				tooltip.show()
		tooltip_using = false
	)
	camera.position = tilemap.map_to_local(tilemap.get_used_rect().get_center())
	
	tilemap_overlay.drawer = overlay_drawer
	
	var main_player = Game.players[0] as Player
	main_player.on_state_callback = Callable(on_state_animation)
		
	for n in hand.get_children():
		hand.remove_child(n)
		n.queue_free()
		
	Game.state_changed.connect(on_state_changed)
	Game.battle_player_changed.connect(on_battle_player_changed)
	Game.attack_commited.connect(on_attack_commited)
	
	var update_production = func(o, n):
		if production_text_tween:
			production_text_tween.kill()
		production_text_tween = get_tree().create_tween()
		production_text_tween.tween_method(func(v):
			production_text.text = "%dP" % v,
			o, n, 0.5
		)
		production_text_tween.tween_callback(func():
			production_text_tween = null
		)
	update_production.call(0, main_player.production)
	main_player.production_changed.connect(update_production)
	
	Game.change_state(0)

func _process(delta: float) -> void:
	pass
	
