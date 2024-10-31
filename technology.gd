class_name Technology

static var config : ConfigFile = null

var tech_name : String
var cost_science : int
var deps : Array
var values : Dictionary
var targets : Dictionary
var level : int = 0
var max_level : int
var display_name : String
var description : String
var icon : String
var coord : Vector2i

static func get_info(key : String):
	if !config:
		config = ConfigFile.new()
		config.load("res://technologies.ini")
	var ret = {}
	ret.cost_science = config.get_value(key, "cost_science")
	ret.deps = config.get_value(key, "deps")
	ret.values = config.get_value(key, "values")
	ret.targets = config.get_value(key, "targets")
	ret.max_level = config.get_value(key, "max_level")
	ret.display_name = config.get_value(key, "display_name")
	ret.description = config.get_value(key, "description")
	ret.icon = config.get_value(key, "icon")
	ret.coord = config.get_value(key, "coord")
	return ret

static func load():
	if !config:
		config = ConfigFile.new()
		config.load("res://technologies.ini")
	var ret = {}
	for name in config.get_sections():
		var info = get_info(name)
		var t = Technology.new()
		t.tech_name = name
		t.cost_science = info.cost_science
		t.deps = info.deps
		t.values = info.values
		t.targets = info.targets
		t.max_level = info.max_level
		t.display_name = info.display_name
		t.description = info.description
		t.icon = info.icon
		t.coord = info.coord
		ret[name] = t
	return ret
	
func get_value(name, level):
	var k = "%s%d" % [name, level]
	if values.has(k):
		return values[k]
	return 0
	
func acquired(player : Player):
	if level >= max_level:
		return false
	level += 1
	
	for t in targets:
		var name = targets[t]
		if player.modifiers.has(name):
			var previous_value = get_value(t, level - 1)
			var new_value = get_value(t, level)
			var k = "%s%d" % [t, level]
			player.change_modifier(name, new_value - previous_value)
	
	return true
