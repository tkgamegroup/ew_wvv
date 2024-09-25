const Tile = preload("res://tile.gd")

signal territory_changed
signal building_changed

var id : int
var coord : Vector2i
var territories : Dictionary
var buildings : Dictionary
var color : Color
var production : int = 100
signal production_changed
var gold : int = 0
signal gold_changed
var avaliable_constructions : Array

var unused_territories : int = 0
var units : Array

var troop_units : Array
var troop_target : Vector2i
var troop_mobility : int
var troop_path : Array

var on_state_callback : Callable

func _init(_id : int) -> void:
	id = _id
	color = Color.from_hsv(id / 6.0, 0.5, 1)
	
	avaliable_constructions.append("lumber_mill")
	avaliable_constructions.append("barracks")
	
func add_territory(coord : Vector2i):
	var tile = Game.map[coord] as Tile
	if tile.player == -1:
		if !territories.has(coord):
			tile.player = id
			territories[coord] = 1
			territory_changed.emit(id)
			return true
	return false

func add_building(coord : Vector2i, name : String):
	if territories.has(coord):
		var tile = Game.map[coord]
		if tile.building == "":
			var info = Building.get_info(name)
			tile.label = info.display_name
			tile.building = name
			var building = Building.new(name)
			buildings[coord] = building
			building_changed.emit(id)
			return true
	return false
	
func add_production(v : int):
	var old_value = production
	production += v
	production_changed.emit(old_value, production)
	
func calc_troop_mobility():
	if troop_units.is_empty():
		troop_mobility = 0
	else:
		troop_mobility = Unit.get_info(troop_units[0]).mobility
		for i in range(1, troop_units.size() - 1):
			troop_mobility = min(troop_mobility, Unit.get_info(troop_units[i]).mobility)
	
func move_unit_to_troop(name : String):
	for i in units.size():
		if units[i] == name:
			units.remove_at(i)
			troop_units.append(name)
			calc_troop_mobility()
			break
	
func move_unit_from_troop(name : String):
	for i in troop_units.size():
		if troop_units[i] == name:
			troop_units.remove_at(i)
			units.append(name)
			calc_troop_mobility()
			break
	
func on_state():
	if on_state_callback.is_valid():
		on_state_callback.call("begin", self)
	for c in buildings:
		var building = buildings[c]
		if building.type == Building.City:
			if Game.state != Game.StatePrepare:
				continue
			if on_state_callback.is_valid():
				on_state_callback.call("next_building", c)
			if on_state_callback.is_valid():
				on_state_callback.call("territory", 2)
			else:
				unused_territories += 2
		elif building.type == Building.ProductionBuilding:
			if Game.state != Game.StatePrepare:
				continue
			if on_state_callback.is_valid():
				on_state_callback.call("next_building", c)
			if on_state_callback.is_valid():
				on_state_callback.call("production", building.ext["production"])
			else:
				production += building.ext["production"]
		elif building.type == Building.BarracksBuilding:
			if Game.state != Game.StateBattle:
				continue
			if on_state_callback.is_valid():
				on_state_callback.call("next_building", c)
			if on_state_callback.is_valid():
				var data = {}
				data.unit_name = building.ext["produce_unit_name"]
				data.unit_count = building.ext["produce_unit_count"]
				on_state_callback.call("unit", data)
			else:
				for i in building.ext["produce_unit_count"]:
					units.append(building.ext["produce_unit_name"])
	if on_state_callback.is_valid():
		on_state_callback.call("end", null)
