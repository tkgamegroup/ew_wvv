class_name Building

static var config : ConfigFile = null

enum
{
	City,
	ProductionBuilding,
	BarracksBuilding
}

var building_name : String
var type : int
var cost_production : int
var cost_gold : int
var display_name : String = ""
var description : String = ""
var ext : Dictionary

static func get_info(key : String):
	if !config:
		config = ConfigFile.new()
		config.load("res://buildings.ini")
	var ret = {}
	ret.type = config.get_value(key, "type")
	ret.cost_production = config.get_value(key, "cost_production")
	ret.cost_gold = config.get_value(key, "cost_gold")
	ret.display_name = config.get_value(key, "display_name")
	ret.description = config.get_value(key, "description")
	if ret.type == City:
		pass
	elif ret.type == ProductionBuilding:
		ret.production=config.get_value(key, "production")
	elif ret.type == BarracksBuilding:
		ret.produce_unit_name=config.get_value(key, "produce_unit_name")
		var unit_info = Unit.get_info(ret.produce_unit_name)
		ret.produce_unit_display_name = unit_info.display_name
		ret.produce_unit_count=config.get_value(key, "produce_unit_count")
	return ret

func _init(key : String):
	var info = get_info(key)
	building_name = key
	type = info.type
	cost_production = info.cost_production
	cost_gold = info.cost_gold
	display_name = info.display_name
	description = info.description
	if type == City:
		pass
	elif type == ProductionBuilding:
		ext["production"] = info.production
	elif type == BarracksBuilding:
		ext["produce_unit_name"] = info.produce_unit_name
		ext["produce_unit_display_name"] = info.produce_unit_display_name
		ext["produce_unit_count"] = info.produce_unit_count
