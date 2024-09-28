const Tile = preload("res://tile.gd")

signal territory_changed
signal building_changed
signal vision_changed

var id : int
var coord : Vector2i
var territories : Dictionary
var buildings : Dictionary
var color : Color
var vision : Dictionary

var production : int = 100
var gold : int = 0
var science : int = 0
signal production_changed
signal gold_changed
signal science_changed

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
	avaliable_constructions.append("academy")
	
func add_territory(coord : Vector2i):
	var tile = Game.map[coord] as Tile
	if tile.player == -1:
		if !territories.has(coord):
			tile.player = id
			territories[coord] = 1
			territory_changed.emit(id)
			vision[coord] = 1
			for t in Game.get_surrounding_tiles(tile):
				vision[t.coord] = 1
			vision_changed.emit()
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
	if v == 0:
		return
	var old_value = production
	production += v
	production_changed.emit(old_value, production)
	
func add_gold(v : int):
	if v == 0:
		return
	var old_value = gold
	gold += v
	gold_changed.emit(old_value, gold)
	
func add_science(v : int):
	if v == 0:
		return
	var old_value = science
	science += v
	science_changed.emit(old_value, science)
	
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
			if Game.state != Game.ConstructState:
				continue
			if on_state_callback.is_valid():
				on_state_callback.call("next_building", c)
			var processed = false
			if on_state_callback.is_valid():
				if on_state_callback.call("territory", 2):
					processed = true
			if !processed:
				unused_territories += 2
		elif building.type == Building.ProductionBuilding:
			if Game.state != Game.ConstructState:
				continue
			if on_state_callback.is_valid():
				on_state_callback.call("next_building", c)
			var production = building.ext["production"]
			var gold_production = building.ext["gold_production"]
			var science_production = building.ext["science_production"]
			if production > 0:
				var processed = false
				if on_state_callback.is_valid():
					if on_state_callback.call("production", production):
						processed = true
				if !processed:
					self.production += production
			if gold_production > 0:
				var processed = false
				if on_state_callback.is_valid():
					if on_state_callback.call("gold_production", gold_production):
						processed = true
				if !processed:
					gold += gold_production
			if science_production > 0:
				var processed = false
				if on_state_callback.is_valid():
					if on_state_callback.call("science_production", science_production):
						processed = true
				if !processed:
					science += science_production
		elif building.type == Building.BarracksBuilding:
			if Game.state != Game.BattleState:
				continue
			if on_state_callback.is_valid():
				on_state_callback.call("next_building", c)
			var processed = false
			if on_state_callback.is_valid():
				var data = {}
				data.unit_name = building.ext["produce_unit_name"]
				data.unit_count = building.ext["produce_unit_count"]
				if on_state_callback.call("unit", data):
					processed = true
			if !processed:
				for i in building.ext["produce_unit_count"]:
					units.append(building.ext["produce_unit_name"])
	if on_state_callback.is_valid():
		on_state_callback.call("end", null)
