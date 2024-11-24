extends Control

signal clicked

var use_resource : int
var resource_amount : int
@onready var card : Card = $Card

func _ready() -> void:
	card.shadow.hide()
	card.dragable = false

func setup(_use_resource : int, _resource_amount : int):
	use_resource = _use_resource
	resource_amount = _resource_amount
	var color = "red" if Game.player.get_resource(use_resource) < resource_amount else "white"
	$Price.text = "[color=%s]%d[/color][img=20]%s[/img]" % [color, resource_amount, Game.get_resource_icon(use_resource)]

func buy(result : Dictionary):
	if Game.player.get_resource(use_resource) >= resource_amount:
		result.cost_type = use_resource
		result.cost = resource_amount
		if !card.effect.is_empty():
			if card.effect.type == "value_up":
				var target = card.effect.target + "_value"
				Game.player.set(target, Game.player.get(target) + card.effect.value)
			else:
				result.card_data = inst_to_dict(card)
		else:
			result.card_data = inst_to_dict(card)
		return true
	else:
		if use_resource == Game.Gold:
			result.message = "金币不足"
	return false

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				clicked.emit()
