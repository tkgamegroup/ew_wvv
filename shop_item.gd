extends Control

const Player = preload("res://player.gd")

signal clicked

const production_icon = "res://icons/production.png"
const gold_icon = "res://icons/gold.png"
const food_icon = "res://icons/food.png"

var use_resource : int
var resource_amount : int
var card_type : int
var card_name : String
var display_name : String
var icon : String
var amount : int = -1

func setup_with_data(data : Dictionary, _use_resource : int):
	use_resource = _use_resource
	if use_resource == Game.ProductionResource:
		resource_amount = data.cost_production
	elif use_resource == Game.GoldResource:
		resource_amount = data.cost_gold
	elif use_resource == Game.FoodResource:
		resource_amount = data.cost_food
	display_name = data.display_name
	icon = data.icon
	get_node("CardBase/Name").text = display_name
	get_node("CardBase/TextureRect").texture = load(icon)
	if use_resource == Game.ProductionResource:
		$Price.text = "%d[img=20]%s[/img]" % [resource_amount, production_icon]
	elif use_resource == Game.GoldResource:
		$Price.text = "%d[img=20]%s[/img]" % [resource_amount, gold_icon]
	elif use_resource == Game.FoodResource:
		$Price.text = "%d[img=20]%s[/img]" % [resource_amount, food_icon]
	if amount != -1:
		$Amount.visible = true
		$Amount.text = "%d" % amount

func setup_building_item(_name : String, _use_resource : int):
	card_type = Card.BuildingCard
	card_name = _name
	var info = Building.get_info(_name)
	setup_with_data(info, _use_resource)

func setup_unit_item(_name : String, _amount : int):
	card_type = Card.UnitCard
	card_name = _name
	amount = _amount
	var info = Unit.get_info(_name)
	setup_with_data(info, Game.FoodResource)

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				clicked.emit()
