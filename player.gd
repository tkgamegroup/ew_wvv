extends Object

class_name Player

const BuildingPrefab = preload("res://building.tscn")
const UnitPrefab = preload("res://unit.tscn")

var id : int
var coord : Vector2i
var buildings : Dictionary[Vector2i, Building]
var color : Color

var production : int = 150
var gold : int = 200
var energy : int = 0
var max_energy : int = 0
var science : int = 100
var food : int = 3
var gear : int = 0
var ruby_value : int = 100
var emerald_value : int = 100
var sapphire_value : int = 100
var amethyst_value : int = 100
signal energy_changed
signal production_changed
signal gold_changed
signal science_changed
signal food_changed
signal geer_changed

var modifiers : Dictionary

var border_lines : Array[Vector2]

func _init(_id : int) -> void:
	id = _id
	color = Color.from_hsv(id / 6.0, 0.5, 1)
	
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
	if type == Game.GearResource:
		return gear

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

func add_building(coord : Vector2i, name : String):
	var tile = Game.map[coord]
	if !tile.building:
		var info = Building.get_info(name)
		var building = BuildingPrefab.instantiate()
		building.setup(name, coord)
		buildings[coord] = building
		tile.building = building
		Game.scene_root.add_child(building)
		return true
	return false

func remove_building(coord : Vector2i):
	var tile = Game.map[coord]
	if tile.building:
		tile.building = null
		buildings[coord].queue_free()
		buildings.erase(coord)

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

func get_energy(v : int):
	if energy >= v:
		energy -= v
		energy_changed.emit()
		return true
	return false

func restore_energy():
	energy = max_energy
	energy_changed.emit()

func calc_max_energy():
	max_energy = 3
	for c in buildings:
		var building = buildings[c]
		if building.effect.has("type"):
			var type = building.effect["type"]
			if type == "max_energy":
				var op = building.effect["op"]
				if op == "increase":
					max_energy += building.effect["value"]
	energy_changed.emit()
