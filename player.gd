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
var science : int = 100
var food : int = 3
var geer : int = 0
signal production_changed
signal gold_changed
signal science_changed
signal food_changed
signal geer_changed

var avaliable_constructions : Array
var avaliable_trainings : Array
var unused_territories : int = 0
var units : Array

var troop_units : Array
var troop_target : Vector2i
var troop_mobility : int
var troop_path : Array

var modifiers : Dictionary

var on_state_callback : Callable

func _init(_id : int) -> void:
	id = _id
	color = Color.from_hsv(id / 6.0, 0.5, 1)
	
	avaliable_constructions.append("lumber_mill")
	#avaliable_constructions.append("wind_mill")
	avaliable_constructions.append("farm")
	#avaliable_constructions.append("fishing_camp")
	avaliable_constructions.append("academy")
	avaliable_constructions.append("barracks")
	#avaliable_constructions.append("stable")
	#avaliable_constructions.append("rally_point")
	#avaliable_constructions.append("keep")
	#avaliable_constructions.append("black_smith")
	
	modifiers["LUMBER_MILL_PRODUCTION_BOUNS_PERCENTAGE"] = 0
	modifiers["ACADEMY_PRODUCTION_BOUNS_PERCENTAGE"] = 0

func get_resource(type : int):
	if type == Game.ProductionResource:
		return production
	if type == Game.GoldResource:
		return gold
	if type == Game.ScienceResource:
		return science
	if type == Game.FoodResource:
		return food
	if type == Game.GeerResource:
		return geer

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

func add_food(v : int):
	if v == 0:
		return
	var old_value = food
	food += v
	food_changed.emit(old_value, food)

func add_vision(coord : Vector2i, range : int):
	vision[coord] = 1
	var tile = Game.map[coord] as Tile
	for t in Game.get_surrounding_tiles_within(tile, range):
		vision[t.coord] = 1
	vision_changed.emit()

func add_territory(coord : Vector2i):
	var tile = Game.map[coord] as Tile
	if tile.player == -1:
		if !territories.has(coord):
			tile.player = id
			territories[coord] = 1
			territory_changed.emit(id)
			add_vision(coord, 1)
			return true
	return false

func remove_territory(coord : Vector2i):
	if territories.has(coord):
		territories.erase(coord)

func add_building(coord : Vector2i, name : String):
	if territories.has(coord):
		var tile = Game.map[coord]
		if tile.building == "":
			var info = Building.get_info(name)
			tile.label = info.display_name
			tile.building = name
			var building = Building.new(name)
			buildings[coord] = building
			if building.building_name == "lumber_mill":
				var production = building.ext["production"]
				building.ext["production"] = production * (100 + modifiers["LUMBER_MILL_PRODUCTION_BOUNS_PERCENTAGE"]) / 100
			elif building.building_name == "academy":
				var production = building.ext["science_production"]
				building.ext["science_production"] = production * (100 + modifiers["ACADEMY_PRODUCTION_BOUNS_PERCENTAGE"]) / 100
			building_changed.emit(id)
			return true
	return false

func remove_building(coord : Vector2i):
	if territories.has(coord):
		var tile = Game.map[coord]
		if tile.building != "":
			tile.label = ""
			tile.building = ""
			buildings.erase(coord)

func add_unit(name : String, mobility : int = -1):
	var unit = Unit.new(name)
	if mobility != -1:
		unit.mobility = mobility
	units.append(unit)
	return unit

func calc_troop_mobility():
	if troop_units.is_empty():
		troop_mobility = 0
	else:
		troop_mobility = troop_units[0].mobility
		for i in range(1, troop_units.size() - 1):
			troop_mobility = min(troop_mobility, troop_units[i].mobility)
	
func move_unit_to_troop(name : String):
	for i in units.size():
		var unit = units[i]
		if unit.unit_name == name:
			troop_units.append(unit)
			units.remove_at(i)
			calc_troop_mobility()
			break
	
func move_unit_from_troop(name : String):
	for i in troop_units.size():
		var unit = troop_units[i]
		if unit.unit_name == name:
			units.append(unit)
			troop_units.remove_at(i)
			calc_troop_mobility()
			break

func change_modifier(name : String, v : int):
	modifiers[name] += v
	
	if name == "LUMBER_MILL_PRODUCTION_BOUNS_PERCENTAGE":
		for c in buildings:
			var building = buildings[c]
			if building.building_name == "lumber_mill":
				var production = building.ext["production"]
				building.ext["production"] = production * (100 + modifiers["LUMBER_MILL_PRODUCTION_BOUNS_PERCENTAGE"]) / 100
	elif name == "ACADEMY_PRODUCTION_BOUNS_PERCENTAGE":
		for c in buildings:
			var building = buildings[c]
			if building.building_name == "academy":
				var production = building.ext["science_production"]
				building.ext["science_production"] = production * (100 + modifiers["ACADEMY_PRODUCTION_BOUNS_PERCENTAGE"]) / 100
	
func on_state():
	var processed = true
	if on_state_callback.is_valid():
		on_state_callback.call("begin", self)

	var corruped_food = food
	if Game.turn == 1:
		corruped_food = 0
	avaliable_trainings.clear()

	for c in buildings:
		var building = buildings[c]
		if building.type == Building.City:
			if Game.state != Game.PrepareState:
				continue
			if on_state_callback.is_valid():
				on_state_callback.call("next_building", c)

			if Game.turn != 1 && corruped_food > 0:
				processed = false
				if on_state_callback.is_valid():
					if on_state_callback.call("food", -corruped_food):
						processed = true
				if !processed:
					self.add_food(-corruped_food)

			processed = false
			if on_state_callback.is_valid():
				if on_state_callback.call("territory", 2):
					processed = true
			if !processed:
				unused_territories += 2
		elif building.type == Building.ProductionBuilding:
			if Game.state != Game.PrepareState:
				continue
			if on_state_callback.is_valid():
				on_state_callback.call("next_building", c)
			var production = building.ext["production"]
			var gold_production = building.ext["gold_production"]
			var science_production = building.ext["science_production"]
			var food_production = building.ext["food_production"]
			if production > 0:
				processed = false
				if on_state_callback.is_valid():
					if on_state_callback.call("production", production):
						processed = true
				if !processed:
					self.production += production
			if gold_production > 0:
				processed = false
				if on_state_callback.is_valid():
					if on_state_callback.call("gold", gold_production):
						processed = true
				if !processed:
					gold += gold_production
			if science_production > 0:
				processed = false
				if on_state_callback.is_valid():
					if on_state_callback.call("science", science_production):
						processed = true
				if !processed:
					science += science_production
			if food_production > 0:
				processed = false
				if on_state_callback.is_valid():
					if on_state_callback.call("food", food_production):
						processed = true
				if !processed:
					food += food_production
		elif building.type == Building.BarracksBuilding:
			if Game.state != Game.BattleState:
				continue
			var unit_name = building.ext["train_unit_name"]
			var unit_count = building.ext["train_unit_count"]
			avaliable_trainings.append({ "name": unit_name, "amount": unit_count })
	if on_state_callback.is_valid():
		on_state_callback.call("end", null)
