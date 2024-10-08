extends Control

class_name Card

const Player = preload("res://player.gd")
const Tile = preload("res://tile.gd")

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
var display_name : String
var description : String
var icon : String
var cost_resource_type : int = Game.NoneResource
var cost_resource : int = 0

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
	data.display_name = info.display_name + "(卡)"
	data.description = info.description.format(info)
	data.icon = info.icon
	setup_from_data(self, data)
	
func setup_unit_card(_name : String):
	var data = {}
	data.card_name = _name + "_unit"
	data.type = UnitCard
	data.target_type = TargetTroop
	var info = Unit.get_info(_name)
	data.display_name = info.display_name + "(卡)"
	data.description = info.description.format(info)
	data.icon = info.icon
	setup_from_data(self, data)

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
					result.message = "不符合建筑要求的领地类型"
			else:
				result.message = "领地上已经有别的建筑"
		else:
			result.message = "只能在你的领地上使用"
	return false

var tween : Tween = null

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				clicked.emit(event.position)
