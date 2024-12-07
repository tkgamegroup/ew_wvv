extends Control

class_name Card

enum
{
	NormalCard,
	BuildingCard,
	UnitCard
}

enum
{
	TargetNull,
	TargetTile,
	TargetBuilding
}

const Tile = preload("res://tile.gd")

signal clicked

var card_name : String
var type : int
var target_type : int
var last_parent : Control
var display_name : String
var description : String
var icon : String
var cost_energy : int = 1
var effect : Dictionary

var hovering = false
var lock : bool = false
var dragable : bool = true
var dragging : bool = false
var drag_off : Vector2
var selected : bool = false
var xy_quat = Quaternion(Vector3(1, 0, 0), 0)
var z_angle : float = 0.0

var tween_hover : Tween = null
var tween_drag : Tween = null

@onready var shadow = $Shadow
@onready var front = $SubViewport/Front
@onready var back = $SubViewport/Back
@onready var outline = $Outline
@onready var sub_viewport = $SubViewport

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
	ret.cost_energy = config.get_value(key, "cost_energy", 1)
	ret.effect = config.get_value(key, "effect", {})
	return ret

func setup_from_data(data : Dictionary):
	card_name = data.card_name
	type = data.type
	target_type = data.target_type
	display_name = data.display_name
	if data.has("description"):
		description = data.description
	icon = data.icon
	cost_energy = data.cost_energy
	if data.has("effect"):
		effect = data.effect
		
	$SubViewport/Front/Name.text = display_name
	$SubViewport/Front/TextureRect.texture = load(icon)
	$SubViewport/Front/Cost.text = "%d" % cost_energy
			
	init_matrix()
	update_rotation()

func setup(_name : String):
	var info = get_info(_name)
	info.card_name = _name
	setup_from_data(info)
	
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
	data.cost_energy = 1
	setup_from_data(data)
	
func setup_unit_card(_name : String):
	var data = {}
	data.card_name = _name + "_unit"
	data.type = UnitCard
	data.target_type = TargetTile
	var info = Unit.get_info(_name)
	data.display_name = info.display_name
	data.description = info.description.format(info)
	data.icon = info.icon
	setup_from_data(data)

func init_matrix():
	var mat = $Rendered.material as ShaderMaterial
	var proj = Projection()
	proj = Projection.create_perspective(30.0, 1.0, 1.0, 100.0)
	mat.set_shader_parameter("projection", proj)
	var rot = Transform3D()
	mat.set_shader_parameter("rotation", rot)
	var holo_rot = Transform3D()
	holo_rot.basis = Basis(Vector3(0.0, 0.0, 1.0), 27.0)
	mat.set_shader_parameter("holographic_rotation", holo_rot)

func update_rotation():
	var mat : ShaderMaterial = $Rendered.material
	var rot = Transform3D()
	rot.basis = Basis(xy_quat)
	mat.set_shader_parameter("rotation", rot)

func update_dissolve(v : float):
	var mat : ShaderMaterial = $Rendered.material
	mat.set_shader_parameter("dissolve", v)

func select():
	outline.show()
	selected = true

func deselect():
	outline.hide()
	selected = false

func front_face():
	front.visible = true
	back.visible = false
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func back_face():
	front.visible = false
	back.visible = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func on_mouse_entered():
	hovering = true
	z_index = 1
	if tween_hover:
		tween_hover.kill()
		tween_hover = null
	if lock || dragging:
		return
	tween_hover = get_tree().create_tween()
	tween_hover.tween_property(self, "scale", Vector2(1.2, 1.2), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_callback(func():
		tween_hover = null
	)

func on_mouse_exited():
	hovering = false
	if !dragging:
		z_index = 0
	if tween_hover:
		tween_hover.kill()
		tween_hover = null
	if lock || dragging:
		return
	tween_hover = get_tree().create_tween()
	tween_hover.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_callback(func():
		tween_hover = null
	)

func start_drag():
	if lock || dragging || !dragable:
		return
	dragging = true
	z_index = 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	last_parent = get_parent()
	var ui_root = get_tree().current_scene.find_child("UI")
	reparent(ui_root)
	if tween_drag:
		tween_drag.kill()
		tween_drag = null
	tween_drag = get_tree().create_tween()
	if target_type != TargetNull:
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
	z_index = 0
	mouse_filter = Control.MOUSE_FILTER_STOP
	reparent(last_parent)
	if tween_drag:
		tween_drag.kill()
		tween_drag = null
	tween_drag = get_tree().create_tween()
	tween_drag.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween_drag.tween_callback(func():
		tween_drag = null
	)

func _ready() -> void:
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)

func _process(delta: float) -> void:
	if !lock && !dragging && hovering:
		var mpos = get_local_mouse_position()
		var rect = get_rect()
		var sz = get_rect().size
		var dir = Vector3(mpos.x - sz.x * 0.5, mpos.y - sz.y * 0.5, 0.0).normalized()
		dir = dir.cross(Vector3(0, 0, 1))
		xy_quat = Quaternion(dir, min(mpos.length() / 100, deg_to_rad(12)))
	if dragging:
		if z_angle != 0:
			z_angle = z_angle * 0.9
		rotation_degrees = z_angle
	
	var screen_center = get_viewport_rect().size / 2
	var dist_to_center = get_global_rect().get_center().x - screen_center.x
	shadow.position.x = lerp(0.0, -sign(dist_to_center) * 20, abs(dist_to_center / screen_center.x))
	
	if !lock:
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
