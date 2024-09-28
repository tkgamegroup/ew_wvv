class_name Technology

static var config : ConfigFile = null

var tech_name : String
var cost_science : int
var deps : Array
var display_name : String
var description : String = ""
var coord : Vector2i

static func load():
	if !config:
		config = ConfigFile.new()
		config.load("res://technologies.ini")
	var ret = {}
	for name in config.get_sections():
		var t = Technology.new()
		t.tech_name = name
		t.cost_science = config.get_value(name, "cost_science")
		t.deps = config.get_value(name, "deps")
		t.display_name = config.get_value(name, "display_name")
		var wtf = var_to_str(Vector2i(10, 9))
		t.coord = config.get_value(name, "coord")
		ret[name] = t
	return ret
	
func acquired():
	pass
