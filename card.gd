extends Control

class_name Card

enum
{
	NormalCard,
	TerritoryCard,
	BuildingCard,
	UnitCard
}

enum
{
	TargetNull,
	TargetTile,
	TargetTroop
}

signal clicked

var card_name : String
var type : int
var target_type : int
var dragging : bool = false
var drag_off : Vector2
var last_parent : Control
var selected : bool = false
var display_name : String
var description : String
var icon : String
var cost_resource_type : int = Game.NoneResource
var cost_resource : int = 0
var xy_quat = Quaternion(Vector3(1, 0, 0), 0)
var z_angle : float = 0.0

var tween_hover : Tween = null
var tween_drag : Tween = null

var shadow : Control = null

static var config : ConfigFile = null

static func get_info(key : String):
	if !config:
		config = ConfigFile.new()
		config.load("res://cards.ini")
	var ret = {}
	ret.type = config.get_value(key, "type")
	ret.target_type = config.get_value(key, "target_type")
	ret.display_name = config.get_value(key, "display_name")
	ret.description = config.get_value(key, "description")
	ret.icon = config.get_value(key, "icon")
	ret.cost_resource_type = config.get_value(key, "cost_resource_type", 0)
	ret.cost_resource = config.get_value(key, "cost_resource", 0)
	return ret

static func setup_from_data(dst : Control, data : Dictionary):
	if is_instance_of(dst, Card):
		dst.card_name = data.card_name
		dst.type = data.type
		dst.target_type = data.target_type
		dst.display_name = data.display_name
		if data.has("description"):
			dst.description = data.description
		dst.icon = data.icon
		if data.has("cost_resource"):
			dst.cost_resource_type = data.cost_resource_type
			dst.cost_resource = data.cost_resource
		dst.update_projection()
		dst.update_rotation()
		
	dst.find_child("Name").text = data.display_name
	dst.find_child("TextureRect").texture = load(data.icon)
	if data.has("cost_resource"):
		if data.cost_resource_type != Game.NoneResource:
			dst.find_child("Cost").visible = true
			dst.find_child("CostText").text = "%d" % data.cost_resource
			var icon_path = ""
			if data.cost_resource_type == Game.FoodResource:
				icon_path = "res://icons/food.png"
			dst.find_child("CostIcon").texture = load(icon_path)

func setup(_name : String):
	var info = get_info(_name)
	info.card_name = _name
	setup_from_data(self, info)
	
func setup_building_card(_name : String):
	var data = {}
	data.card_name = _name + "_building"
	data.type = BuildingCard
	data.target_type = TargetTile
	var info = Building.get_info(_name)
	data.display_name = info.display_name
	data.description = info.description.format(info)
	data.description = "地块需求：%s\n" % Building.get_need_terrain_text(info.need_terrain) + data.description
	data.icon = info.icon
	setup_from_data(self, data)
	
func setup_unit_card(_name : String):
	var data = {}
	data.card_name = _name + "_unit"
	data.type = UnitCard
	data.target_type = TargetTroop
	var info = Unit.get_info(_name)
	data.display_name = info.display_name
	data.description = info.description.format(info)
	data.icon = info.icon
	setup_from_data(self, data)

func update_projection():
	var rendered = find_child("Rendered") as Sprite2D
	var mat = rendered.material as ShaderMaterial
	var proj = Projection()
	proj = Projection.create_perspective(30.0, 1.0, 1.0, 100.0)
	mat.set_shader_parameter("projection", proj)

func update_rotation():
	var rendered = find_child("Rendered") as Sprite2D
	var mat = rendered.material as ShaderMaterial
	var rot = Transform3D()
	rot.basis = Basis(xy_quat)
	mat.set_shader_parameter("rotation", rot)

func select():
	find_child("Outline").show()
	selected = true

func deselect():
	find_child("Outline").hide()
	selected = false

func on_mouse_entered():
	if tween_hover:
		tween_hover.kill()
		tween_hover = null
	if dragging:
		return
	tween_hover = get_tree().create_tween()
	tween_hover.tween_property(self, "scale", Vector2(1.2, 1.2), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_callback(func():
		tween_hover = null
	)

func on_mouse_exited():
	if tween_hover:
		tween_hover.kill()
		tween_hover = null
	if dragging:
		return
	tween_hover = get_tree().create_tween()
	tween_hover.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_callback(func():
		tween_hover = null
	)

func start_drag():
	if dragging:
		return
	dragging = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	last_parent = get_parent()
	var ui_root = get_tree().current_scene.find_child("CanvasLayer")
	reparent(ui_root)
	if tween_drag:
		tween_drag.kill()
		tween_drag = null
	tween_drag = get_tree().create_tween()
	tween_drag.tween_property(self, "scale", Vector2(0.4, 0.4), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	#tween_drag.parallel().tween_property(self, "modulate:a", 0.8, 0.25)
	tween_drag.parallel().tween_property(self, "rotation_degrees", 0.0, 0.25)
	tween_drag.tween_callback(func():
		tween_drag = null
	)

func release_drag():
	if !dragging:
		return
	dragging = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	reparent(last_parent)
	if tween_drag:
		tween_drag.kill()
		tween_drag = null
	tween_drag = get_tree().create_tween()
	tween_drag.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	#tween_drag.parallel().tween_property(self, "modulate:a", 1, 0.25)
	tween_drag.tween_callback(func():
		tween_drag = null
	)

func activate_on_tile(tile_coord : Vector2i, result : Dictionary) -> bool :
	if type == TerritoryCard:
		if Game.state != Game.PrepareState:
			result.message = "只能在准备阶段使用"
			return false
		var ok = false
		if !Game.main_player.territories.has(tile_coord):
			var tile = Game.map[tile_coord] as Tile
			if tile.player == -1:
				if tile.neutral_units.is_empty():
					for t in Game.get_surrounding_tiles(tile):
						if Game.main_player.territories.has(t.coord):
							ok = true
							break
					if !ok:
						result.message = "必须放在已有领地旁边"
				else:
					result.message = "此地块上有野生生物，不能占领"
			else:
				result.message = "此地块已被其他玩家占领"
		else:
			result.message = "已经有此领地"
		if ok:
			if Game.main_player.unused_territories > 0:
				if Game.main_player.add_territory(tile_coord):
					Game.main_player.unused_territories -= 1
					return true
			else:
				result.message = "程序错误, unused_territories == 0"
	elif type == BuildingCard:
		if Game.state != Game.PrepareState:
			result.message = "只能在准备阶段使用"
			return false
		if Game.main_player.territories.has(tile_coord):
			var tile = Game.map[tile_coord] as Tile
			if tile.building == "":
				var name = card_name.substr(0, card_name.length() - 9)
				var info = Building.get_info(name)
				if info.need_terrain.find(tile.terrain) != -1:
					if Game.main_player.add_building(tile_coord, name):
						return true
				else:
					result.message = "不符合建筑要求的地块类型"
			else:
				result.message = "领地上已经有别的建筑"
		else:
			result.message = "只能在你的领地上使用"
	return false

func _ready() -> void:
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)
	
	shadow = find_child("Shadow")

func _process(delta: float) -> void:
	if !dragging:
		var mpos = get_local_mouse_position()
		var rect = get_rect()
		var sz = get_rect().size
		if mpos.x > 0 && mpos.y > 0 && mpos.x < sz.x && mpos.y < sz.y:
			var dir = Vector3(mpos.x - sz.x * 0.5, mpos.y - sz.y * 0.5, 0.0).normalized()
			dir = dir.cross(Vector3(0, 0, 1))
			xy_quat = Quaternion(dir, min(mpos.length() / 100, deg_to_rad(7)))
	else:
		if z_angle != 0:
			z_angle = z_angle * 0.9
		rotation_degrees = z_angle
	
	var screen_center = get_viewport_rect().size / 2
	var dist_to_center = get_global_rect().get_center().x - screen_center.x
	shadow.position.x = lerp(0.0, -sign(dist_to_center) * 20, abs(dist_to_center / screen_center.x))
	
	var angle = xy_quat.get_angle()
	if angle * angle > 0:
		xy_quat = xy_quat.slerp(Quaternion(0.0, 0.0, 0.0, 1.0), 0.05)
		if angle * angle < 0.0005:
			xy_quat = Quaternion(0.0, 0.0, 0.0, 1.0)
		update_rotation()

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				clicked.emit()
				drag_off = event.position
				start_drag()

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		if dragging:
			position = event.global_position - Vector2(Game.card_hf_width, Game.card_hf_height)
			var vel = event.velocity
			var len = vel.length()
			if len < 1:
				xy_quat = xy_quat.slerp(Quaternion(0.0, 0.0, 0.0, 1.0), 0.1)
			else:
				var dir = Vector3(vel.x, vel.y, 0.0).normalized()
				dir = dir.cross(Vector3(0, 0, 1))
				z_angle = lerp(z_angle, sign(vel.x) * min(abs(vel.x), 25.0), 0.1)
				var quat = Quaternion(dir, deg_to_rad(min(len, 25.0)))
				xy_quat = xy_quat.slerp(quat, 0.1)
			update_rotation()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if !event.pressed:
				release_drag()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				release_drag()
	
