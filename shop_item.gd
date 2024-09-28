extends Control

const Player = preload("res://player.gd")

signal clicked

var cost_production : int = 0
var cost_gold : int = 0
var display_name : String = ""

func setup_territory_item():
	cost_production = 50
	cost_gold = 100
	display_name = "领地"
	get_node("CardBase/Name").text = display_name
	$Price.text = "%dP" % cost_production

func setup_building_item(_key : String):
	var info = Building.get_info(_key)
	cost_production = info.cost_production
	cost_gold = info.cost_gold
	display_name = info.display_name
	get_node("CardBase/Name").text = display_name
	$Price.text = "%dP" % cost_production

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				clicked.emit()
