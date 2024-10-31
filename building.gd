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
var defense : int
var display_name : String
var description : String
var icon : String
var image_tile_id : int
var ext : Dictionary

static func get_need_terrain_text(need_terrain : Array):
	var need_terrain_text = ""
	for t in need_terrain:
		if !need_terrain_text.is_empty():
			need_terrain_text += ", "
		need_terrain_text += Tile.get_terrain_text(t)
	return need_terrain_text

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
	ret.image_tile_id = config.get_value(name, "image_tile_id")
	
	ret.production = config.get_value(name, "production", 0)
	ret.gold_production = config.get_value(name, "gold_production", 0)
	ret.science_production = config.get_value(name, "science_production", 0)
	ret.food_production = config.get_value(name, "food_production", 0)
	ret.geer_production = config.get_value(name, "geer_production", 0)
	if ret.type == City:
		pass
	elif ret.type == ProductionBuilding:
		pass
	elif ret.type == BarracksBuilding:
		ret.trainnings = config.get_value(name, "trainnings")
	elif ret.type == RallyPointBuilding:
		ret.additional_mobility = config.get_value(name, "additional_mobility")
	elif ret.type == KeepBuilding:
		ret.additional_defense = config.get_value(name, "additional_defense")
	return ret

func _init(key : String):
	var info = get_info(key)
	building_name = key
	type = info.type
	display_name = info.display_name
	description = info.description
	icon = info.icon
	image_tile_id = info.image_tile_id
	
	ext["production"] = info.production
	ext["gold_production"] = info.gold_production
	ext["science_production"] = info.science_production
	ext["food_production"] = info.food_production
	ext["geer_production"] = info.geer_production
	if type == City:
		pass
	elif type == ProductionBuilding:
		pass
	elif type == BarracksBuilding:
		ext["trainnings"] = info.trainnings
	elif type == RallyPointBuilding:
		ext["additional_mobility"] = info.additional_mobility
	elif type == KeepBuilding:
		ext["additional_defense"] = info.additional_defense

func add_trainning(name : String, count : int):
	pass

func set_trainning(name : String):
	var trainnings = ext["trainnings"] as Dictionary
	if trainnings.has(name):
		ext["train_unit_name"] = name
		var unit_info = Unit.get_info(name)
		ext["train_unit_display_name"] = unit_info.display_name
		ext["train_unit_count"] = trainnings[name]
		description = get_info(building_name).description
		description += "\n每回合训练最多[b]{train_unit_count}[/b]个[b]{train_unit_display_name}[/b]"
