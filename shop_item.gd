extends Control

signal clicked

var use_resource : int
var resource_amount : int
var card_type : int
var card_name : String
var display_name : String
var icon : String
var amount : int = -1

func setup_with_data(data : Dictionary, _use_resource : int):
	use_resource = _use_resource
	if use_resource == Game.ProductionResource && data.has("cost_production"):
		resource_amount = data.cost_production
	elif use_resource == Game.GoldResource && data.has("cost_gold"):
		resource_amount = data.cost_gold
	elif use_resource == Game.FoodResource && data.has("cost_food"):
		resource_amount = data.cost_food
	display_name = data.display_name
	icon = data.icon
	get_node("CardBase/Name").text = display_name
	get_node("CardBase/TextureRect").texture = load(icon)
	var color = "red" if Game.main_player.get_resource(use_resource) < resource_amount else "white"
	$Price.text = "[color=%s]%d[/color][img=20]%s[/img]" % [color, resource_amount, Game.get_resource_icon(use_resource)]
	if amount != -1:
		$Amount.visible = true
		$Amount.text = "%d" % amount
		if amount == 0:
			$Amount.add_theme_color_override("font_color", Color.RED)

func setup_territory_item(_use_resource : int, _cost : int):
	card_type = Card.TerritoryCard
	card_name = "territory"
	var info = Card.get_info(card_name)
	resource_amount = _cost
	setup_with_data(info, _use_resource)
	pass

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

func buy(result : Dictionary):
	if Game.main_player.get_resource(use_resource) >= resource_amount:
		if amount == -1 || amount > 0:
			result.cost_type = use_resource
			result.cost = resource_amount
			result.card_data = inst_to_dict(self)
			if amount > 0:
				amount -= 1
				if amount == 0:
					$Amount.add_theme_color_override("font_color", Color.RED)
			return true
		else:
			result.message = "存货不足"
			return false
	else:
		if use_resource == Game.ProductionResource:
			result.message = "生产力不足"
		elif use_resource == Game.GoldResource:
			result.message = "金币不足"
		elif use_resource == Game.FoodResource:
			result.message = "食物不足"
	return false

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				clicked.emit()
