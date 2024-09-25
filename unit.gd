
class_name Unit

static var config : ConfigFile = null

var unit_name : String
var display_name : String
var atk : int
var def : int
var mobility : int

static func get_info(key : String):
	if !config:
		config = ConfigFile.new()
		config.load("res://units.ini")
	var ret = {}
	ret.display_name = config.get_value(key, "display_name")
	ret.atk = config.get_value(key, "atk")
	ret.def = config.get_value(key, "def")
	ret.mobility = config.get_value(key, "mobility")
	
	return ret

func _init(key : String):
	var info = get_info(key)
	unit_name = key
	display_name = info.display_name
	atk = info.atk
	def = info.def
	mobility = info.mobility
