
class_name Unit

static var config : ConfigFile = null

var unit_name : String
var display_name : String
var description : String
var icon : String
var atk : int
var def : int
var mobility : int
var cost_food : int

static func get_info(key : String):
	if !config:
		config = ConfigFile.new()
		config.load("res://units.ini")
	var ret = {}
	ret.display_name = config.get_value(key, "display_name")
	ret.description = config.get_value(key, "description", "")
	ret.icon = config.get_value(key, "icon")
	ret.atk = config.get_value(key, "atk")
	ret.def = config.get_value(key, "def")
	ret.mobility = config.get_value(key, "mobility")
	ret.cost_food = config.get_value(key, "cost_food")
	
	return ret

func _init(key : String):
	var info = get_info(key)
	unit_name = key
	display_name = info.display_name
	description = info.description
	icon = info.icon
	atk = info.atk
	def = info.def
	mobility = info.mobility
	cost_food = info.cost_food
