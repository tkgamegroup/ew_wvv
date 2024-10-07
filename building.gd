class_name Building

static var config : ConfigFile = null

enum
{
	City,
	ProductionBuilding,
	BarracksBuilding,
	RallyPointBuilding,
	KeepBuilding
}

var building_name : String
var type : int
var cost_production : int
var cost_gold : int
var need_terrain : Array
var display_name : String
var description : String
var tile_id : int
var ext : Dictionary

static func get_info(name : String):
	if !config:
		config = ConfigFile.new()
		config.load("res://buildings.ini")
	var ret = {}
	var vars = config.get_section_keys(name)
	ret.type = config.get_value(name, "type")
	ret.cost_production = config.get_value(name, "cost_production")
	ret.cost_gold = config.get_value(name, "cost_gold")
	ret.need_terrain = config.get_value(name, "need_terrain")
	ret.display_name = config.get_value(name, "display_name")
	ret.description = config.get_value(name, "description")
	ret.icon = config.get_value(name, "icon")
	ret.tile_id = config.get_value(name, "tile_id")
	if ret.type == City:
		pass
	elif ret.type == ProductionBuilding:
		ret.production = config.get_value(name, "production", 0)
		ret.gold_production = config.get_value(name, "gold_production", 0)
		ret.science_production = config.get_value(name, "science_production", 0)
		ret.food_production = config.get_value(name, "food_production", 0)
		ret.geer_production = config.get_value(name, "geer_production", 0)
	elif ret.type == BarracksBuilding:
		ret.train_unit_name = config.get_value(name, "train_unit_name")
		var unit_info = Unit.get_info(ret.train_unit_name)
		ret.train_unit_display_name = unit_info.display_name
		ret.train_unit_count = config.get_value(name, "train_unit_count")
	elif ret.type == RallyPointBuilding:
		ret.additional_mobility = config.get_value(name, "additional_mobility")
	elif ret.type == KeepBuilding:
		ret.additional_defense = config.get_value(name, "additional_defense")
	return ret

func _init(key : String):
	var info = get_info(key)
	building_name = key
	type = info.type
	cost_production = info.cost_production
	cost_gold = info.cost_gold
	need_terrain = info.need_terrain
	display_name = info.display_name
	description = info.description
	tile_id = info.tile_id
	if type == City:
		pass
	elif type == ProductionBuilding:
		ext["production"] = info.production
		ext["gold_production"] = info.gold_production
		ext["science_production"] = info.science_production
		ext["food_production"] = info.food_production
		ext["geer_production"] = info.geer_production
	elif type == BarracksBuilding:
		ext["train_unit_name"] = info.train_unit_name
		ext["train_unit_display_name"] = info.train_unit_display_name
		ext["train_unit_count"] = info.train_unit_count
	elif type == RallyPointBuilding:
		ext["additional_mobility"] = info.additional_mobility
	elif type == KeepBuilding:
		ext["additional_defense"] = info.additional_defense
