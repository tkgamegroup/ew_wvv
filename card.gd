extends Control

class_name Card

const Player = preload("res://player.gd")
const Tile = preload("res://tile.gd")

enum
{
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
	return ret

func setup(_name : String):
	card_name = _name
	var info = get_info(_name)
	if !config:
		config = ConfigFile.new()
		config.load("res://cards.ini")
	type = info.type
	target_type = info.target_type
	display_name = info.display_name
	description = info.description
	icon = info.icon
	get_node("CardBase/Name").text = display_name
	get_node("CardBase/TextureRect").texture = load(icon)
	
func copy(oth : Card):
	card_name = oth.card_name
	type = oth.type
	target_type = oth.target_type
	display_name = oth.display_name
	description = oth.description
	icon = oth.icon
	get_node("CardBase/Name").text = display_name
	get_node("CardBase/TextureRect").texture = load(icon)
	
func setup_building_card(_name : String):
	card_name = _name + "_building"
	type = BuildingCard
	target_type = TargetTile
	var info = Building.get_info(_name)
	display_name = info.display_name
	icon = info.icon
	get_node("CardBase/Name").text = display_name
	get_node("CardBase/TextureRect").texture = load(icon)
	
func setup_unit_card(_name : String):
	card_name = _name + "_unit"
	type = UnitCard
	target_type = TargetTroop
	var info = Unit.get_info(_name)
	display_name = info.display_name
	icon = info.icon
	get_node("CardBase/Name").text = display_name
	get_node("CardBase/TextureRect").texture = load(icon)

func activate_on_tile(tile_coord : Vector2i) -> bool :
	var main_player = Game.players[0] as Player
	if type == TerritoryCard:
		var ok = false
		if !main_player.territories.has(tile_coord):
			var tile = Game.map[tile_coord]
			if tile.player == -1:
				for t in Game.get_surrounding_tiles(tile):
					if main_player.territories.has(t.coord):
						ok = true
						break
		if ok:
			if main_player.unused_territories > 0:
				if main_player.add_territory(tile_coord):
					main_player.unused_territories -= 1
					return true
	elif type == BuildingCard:
		if main_player.territories.has(tile_coord):
			var tile = Game.map[tile_coord] as Tile
			var name = card_name.substr(0, card_name.length() - 9)
			var info = Building.get_info(name)
			if tile.building == "" && info.need_terrain.find(tile.terrain) != -1:
				if main_player.add_building(tile_coord, name):
					return true
	return false

var tween : Tween = null

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				clicked.emit(event.position)
