extends Control

signal clicked

var use_resource : int
var resource_amount : int
@onready var card : Card = $Card
@onready var price_text = $Price

func _ready() -> void:
	card.shadow.hide()
	card.dragable = false
	update_price()

func update_price():
	var color = "red" if Game.player.get_resource(use_resource) < resource_amount else "white"
	price_text.text = "[color=%s]%d[/color][img=20]%s[/img]" % [color, resource_amount, Game.get_resource_icon(use_resource)]

func setup(_use_resource : int, _resource_amount : int):
	use_resource = _use_resource
	resource_amount = _resource_amount

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				clicked.emit()
