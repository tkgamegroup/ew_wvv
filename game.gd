extends Node2D

enum
{
	PrepareState,
	BattleState
}

enum
{
	NoneResource,
	ProductionResource,
	GoldResource,
	ScienceResource,
	FoodResource,
	GearResource
}

const card_width = 120
const card_height = 144
const card_hf_width = card_width / 2
const card_hf_height = card_height / 2

var cx = 20
var cy = 10

var map : Dictionary[Vector2i, Tile]
var players : Dictionary[int, Player]
var techs : Dictionary
var round : int = 0
var state : int = 0
const main_player_id = 0
const neutral_player_id = 255
var main_player : Player = null
var neutral_player : Player = null
signal game_setup
signal state_changed
signal attack_commited

var hovering_tile = Vector2i(-1, -1)

var battle_attacker : int = -1
var battle_defender : int = -1
var battle_order_list : Array
signal battle_player_changed

var peeding_neutral_attacks : Dictionary

static func SmoothDamp(current : float, target : float, currentVelocity : Dictionary, smoothTime : float, maxSpeed : float , deltaTime : float)->float:
	smoothTime = max(0.0001, smoothTime)
	var num = 2 / smoothTime
	var num2 = num * deltaTime
	var num3 = 1 / (1 + num2 + 0.48 * num2 * num2 + 0.235 * num2 * num2 * num2)
	var num4 = current - target
	var num5 = target
	var num6 = maxSpeed * smoothTime
	num4 = clamp (num4, -num6, num6)
	target = current - num4
	var num7 = (currentVelocity.v + num * num4) * deltaTime
	currentVelocity.v = (currentVelocity.v - num * num7) * num3
	var num8 = target + (num4 + num7) * num3
	if num5 - current > 0 == num8 > num5:
		num8 = num5
		currentVelocity.v = (num8 - num5) / deltaTime
	return num8

static func get_shuffled_indices(n : int):
	var ret = []
	for i in n:
		ret.append(i)
	ret.shuffle()
	return ret

static func get_resource_name(type : int):
	if type == Game.ProductionResource:
		return "production"
	if type == Game.GoldResource:
		return "gold"
	if type == Game.ScienceResource:
		return "science"
	if type == Game.FoodResource:
		return "food"

static func get_resource_icon(type : int):
	if type == Game.ProductionResource:
		return "res://icons/production.png"
	if type == Game.GoldResource:
		return "res://icons/gold.png"
	if type == Game.ScienceResource:
		return "res://icons/science.png"
	if type == Game.FoodResource:
		return "res://icons/food.png"

func add_player(id : int):
	var cands = []
	if id == neutral_player_id:
		cands.append(map[Vector2i(0, 0)])
	else:
		for c in map:
			if c.x > 3 && c.x < cx - 4 && c.y > 3 && c.y < cy - 4:
				var t = map[c] as Tile
				if t.player == -1 && t.terrain == Tile.TerrainPlain && t.neutral_units.is_empty():
					cands.append(t)
	if cands.is_empty():
		return null
	var coord = cands.pick_random().coord
	
	var player = Player.new(id)
	player.coord = coord
	player.add_territory(coord)
	player.add_building(coord, "city")
	players[id] = player
	player.add_vision(coord, 2)
	var tile = map[coord] as Tile
	tile.resource_amount = 0
	return player

func get_surrounding_tiles(tile : Tile) -> Array :
	var ret = []
	if tile.tile_b.x != -1:
		ret.append(map[tile.tile_b])
	if tile.tile_lb.x != -1:
		ret.append(map[tile.tile_lb])
	if tile.tile_lt.x != -1:
		ret.append(map[tile.tile_lt])
	if tile.tile_rb.x != -1:	
		ret.append(map[tile.tile_rb])
	if tile.tile_rt.x != -1:
		ret.append(map[tile.tile_rt])
	if tile.tile_t.x != -1:
		ret.append(map[tile.tile_t])
	return ret
	
func get_surrounding_tiles_within(tile : Tile, range : int) -> Array:
	var ret = []
	if range <= 0:
		return ret
	var start = 0
	var end = 1
	ret.append(tile)
	while range > 0:
		for i in range(start, end):
			var t = ret[i]
			for _t in get_surrounding_tiles(t):
				if !ret.has(_t):
					ret.append(_t)
		start = end
		end = ret.size()
		range -= 1
	return ret
	
func find_path_on_map(start : Vector2i, end : Vector2i, vision : Dictionary) -> Array[Tile]:
	var ret : Array[Tile] = []
	var start_tile = map[start] as Tile
	if !start_tile.passable:
		return []
	if start.x == end.x && start.y == end.y:
		ret.append(start_tile)
		return ret
	var end_tile = map[end] as Tile
	if !end_tile.passable:
		return []
	var scaned = {}
	scaned[start] = { "d": 0, "read": false }
	var max_d = max(cx, cy)
	var found = false
	for c in scaned:
		if !scaned[c].read:
			for t in get_surrounding_tiles(map[c]):
				if !t.passable:
					continue
				if !vision.is_empty() && !vision.has(t.coord):
					continue
				if !scaned.has(t.coord):
					var d = scaned[c].d + 1
					if d > max_d:
						return []
					scaned[t.coord] = { "d": d, "read": false }
				if t == end_tile:
					found = true
					break
			scaned[c].read = true
		if found:
			break
	if !found:
		return []
	ret.append(end_tile)
	found = false
	var reverse_loop = false
	while true:
		var t = ret[0]
		var _d = scaned[t.coord].d
		var surroundings = get_surrounding_tiles(t)
		var _range
		if reverse_loop:
			_range = range(surroundings.size() - 1, -1, -1)
			reverse_loop = false
		else:
			_range = range(0, surroundings.size(), 1)
			reverse_loop = true
		for i in _range:
			var _t = surroundings[i]
			if _t == start_tile:
				found = true
				break
			if scaned.has(_t.coord) && scaned[_t.coord].d == _d - 1:
				ret.push_front(_t)
				break
		if found:
			break
	ret.push_front(start_tile)
	return ret
	
func change_state(new_state : int) :
	state = new_state
	if state == PrepareState:
		round += 1
		
		peeding_neutral_attacks.clear()
		for c in map:
			var tile = map[c] as Tile
			if !tile.neutral_units.is_empty():
				var types = tile.get_neutral_unit_types()
				tile.neutral_units.clear()
				for n in types:
					var size = types[n]
					size += max(1, int(float(size) * 0.1))
					for i in size:
						var unit = Unit.new(n)
						tile.neutral_units.append(unit)
				if tile.neutral_units.size() > 20:
					var cands = []
					for t in get_surrounding_tiles(tile):
						if t.player == -1 && t.passable && t.neutral_units.size() < tile.neutral_units.size() / 2:
							cands.append(t)
					if !cands.is_empty():
						var t = cands.pick_random()
						var units1 = []
						var units2 = []
						var num = tile.neutral_units.size() 
						for u in tile.neutral_units:
							if randf() < 0.5:
								units1.append(u.unit_name)
							else:
								units2.append(u.unit_name)
						tile.neutral_units.clear()
						for n in units1:
							var unit = Unit.new(n)
							tile.neutral_units.append(unit)
						t.neutral_units.clear()
						for n in units2:
							var unit = Unit.new(n)
							t.neutral_units.append(unit)
						neutral_player.territory_changed.emit(neutral_player_id)
						break
				if tile.neutral_units.size() > 10:
					var cands = []
					for t in get_surrounding_tiles(tile):
						if t.player == main_player_id && t.passable:
							cands.append(t)
					if !cands.is_empty():
						peeding_neutral_attacks[tile] = cands.pick_random()
		if !peeding_neutral_attacks.is_empty():
			neutral_player.territory_changed.emit(neutral_player_id)

		for id in players:
			var player = players[id] as Player
			player.on_state()
	elif state == BattleState:
		for id in players:
			var player = players[id] as Player
			player.action_skipped = false
			player.on_state()
		battle_order_list.clear()
		for id in players:
			battle_order_list.append(id)
	state_changed.emit()

func is_battle_round_ended():
	for id in players:
		var player = players[id] as Player
		if !player.troop_units.is_empty():
			return false
	return true

func skip_attack():
	if battle_attacker == -1:
		return
	var attacker_player = players[battle_attacker] as Player
	attacker_player.action_skipped = true
	next_attacker()

func able_attack(id):
	var player = players[id] as Player
	if id == main_player_id:
		return !player.action_skipped
	if id == neutral_player_id:
		return !peeding_neutral_attacks.is_empty()
	return player.units.is_empty()

func next_attacker():
	var start_idx = battle_order_list.find(battle_attacker)
	if start_idx == -1:
		start_idx = 1
	battle_attacker = -1
	battle_defender = -1
	var battle_ended = true
	for id in players:
		if able_attack(id):
			battle_ended = false
			break
	if battle_ended:
		change_state(PrepareState)
		return
	for id in players:
		var player = players[id] as Player
		player.troop_units.clear()
		player.troop_target = Vector2i(-1, -1)
		player.troop_mobility = 0
		player.troop_path.clear()
	var idx = start_idx
	while true:
		idx += 1
		if idx == battle_order_list.size():
			idx = 0
		var id = battle_order_list[idx]
		if able_attack(id):
			battle_attacker = id
			break
		if idx == start_idx:
			break
	if battle_attacker != -1 && battle_attacker != main_player_id:
		if battle_attacker == neutral_player_id:
			for start_tile in peeding_neutral_attacks:
				var end_tile = peeding_neutral_attacks[start_tile]
				if end_tile.player == -1:
					peeding_neutral_attacks.erase(start_tile)
					next_attacker()
					return
				var num = start_tile.neutral_units.size()
				if num < 10:
					peeding_neutral_attacks.erase(start_tile)
					next_attacker()
					return
				num /= 2
				for i in num:
					var name = start_tile.neutral_units.pick_random().unit_name
					var unit = Unit.new(name)
					neutral_player.troop_units.append(unit)
					start_tile.remove_neutral_unit(name)
				neutral_player.troop_target = end_tile.coord
				neutral_player.troop_path = [start_tile, end_tile]
				battle_defender = end_tile.player
				peeding_neutral_attacks.erase(start_tile)
				break
		else:
			var attacker_player = players[battle_attacker] as Player
			var num = randi_range(1, attacker_player.units.size())
			for i in num:
				var unit_name = attacker_player.units.pick_random().unit_name
				attacker_player.move_unit_to_troop(unit_name)
			var cands = {}
			for c in attacker_player.territories:
				for t in get_surrounding_tiles_within(map[c], attacker_player.troop_mobility):
					if t.player == main_player_id:
						if !cands.has(t.coord):
							cands[t.coord] = c
			if !cands.is_empty():
				var c = cands.keys().pick_random()
				attacker_player.troop_target = c
				attacker_player.troop_path = find_path_on_map(cands[c], c, {})
				var target_tile = map[c] as Tile
				if target_tile.player != -1:
					battle_defender = target_tile.player
	battle_player_changed.emit()

func commit_attack():
	if battle_attacker == -1:
		return
	var attacker_player = players[battle_attacker]
	if attacker_player.troop_target.x == -1 || attacker_player.troop_target.y == -1 || attacker_player.troop_units.is_empty():
		next_attacker()
		return
	if battle_attacker == main_player_id:
		var target_tile = map[attacker_player.troop_target] as Tile
		if target_tile.player != -1:
			battle_defender = target_tile.player
			var defender_player = players[battle_defender] as Player
			# 根据攻击方的单位数量，AI给出一个猜测
			var num = min(defender_player.units.size(), attacker_player.troop_units.size() + randi_range(-3, +3))
			for i in num:
				var unit_name = defender_player.units.pick_random().unit_name
				defender_player.move_unit_to_troop(unit_name)
	attack_commited.emit()

func cleanup_unit_list(list : Array):
	var ret = []
	for u in list:
		if u != null:
			ret.append(u)
	return ret

var battle_calc_callback : Callable
func battle_calc():
	if battle_attacker == -1:
		return
	var attacker_player = players[battle_attacker] as Player
	var target_tile = map[attacker_player.troop_target] as Tile
	var attacker_units = []
	var defender_units = []
	
	for u in attacker_player.troop_units:
		attacker_units.append(u)
	
	attacker_player.troop_units.clear()
	attacker_player.troop_target = Vector2i(-1, -1)
	attacker_player.troop_mobility = 0
	attacker_player.troop_path.clear()
	
	if target_tile.player == -1:
		for u in target_tile.neutral_units:
			defender_units.append(u)
	else:
		var defender_player = players[target_tile.player] as Player
		for u in defender_player.troop_units:
			defender_units.append(u)
		defender_player.troop_units.clear()
		
	if battle_calc_callback.is_valid():
		var data = {}
		data.attacker_units = attacker_units
		data.defender_units = defender_units
		battle_calc_callback.call("init_fighting", data)

	if !defender_units.is_empty():
		var total_attack = 0
		var total_defense = 0
		for u in attacker_units:
			total_attack += u.atk
		for u in defender_units:
			total_defense += u.def
		var result = {}
		result.attacker_lost = []
		result.defender_lost = []
		if total_attack >= total_defense:
			for i in defender_units.size():
				defender_units[i] = null
				result.defender_lost.append(i)
			var value = total_attack * (float(total_defense) / total_attack)
			var indices = []
			for i in attacker_units.size():
				indices.append(i)
			indices.shuffle()
			for i in indices:
				var u = attacker_units[i]
				if value >= u.atk:
					value -= u.atk
					attacker_units[i] = null
					result.attacker_lost.append(i)
		else:
			for i in attacker_units.size():
				attacker_units[i] = null
				result.attacker_lost.append(i)
			var value = total_defense * (float(total_attack) / total_defense)
			var indices = []
			for i in defender_units.size():
				indices.append(i)
			indices.shuffle()
			for i in indices:
				var u = defender_units[i]
				if value >= u.def:
					value -= u.def
					defender_units[i] = null
					result.defender_lost.append(i)

		attacker_units = cleanup_unit_list(attacker_units)
		defender_units = cleanup_unit_list(defender_units)

		attacker_player.troop_units.clear()
		if target_tile.player == -1:
			target_tile.neutral_units = defender_units
		else:
			var defender_player = players[target_tile.player] as Player
			defender_player.troop_units.clear()
			
		if battle_calc_callback.is_valid():
			battle_calc_callback.call("fighting_result", result)
		
	if battle_calc_callback.is_valid():
		battle_calc_callback.call("fighting_end", null)
		
	if !attacker_units.is_empty():
		if battle_attacker != neutral_player_id:
			if target_tile.player == -1:
				if target_tile.resource_amount > 0:
					var processed = false
					if battle_calc_callback.is_valid():
						var data = {}
						data.value = target_tile.resource_amount
						data.coord = target_tile.coord
						if battle_calc_callback.call(get_resource_name(target_tile.resource_type), data):
							processed = true
					if !processed:
						attacker_player.add_production(target_tile.resource_amount)
					target_tile.resource_amount = 0
		else:
			var defender_player = players[target_tile.player] as Player
			if target_tile.building != "":
				defender_player.remove_building(target_tile.coord)
			else:
				defender_player.remove_territory(target_tile.coord)
	
	if !battle_calc_callback.is_valid():
		next_attacker()

func start_new_game(config : Dictionary):
	round = 0
	
	cx = config.cx
	cy = config.cy
	
	map.clear()
	for x in cx:
		for y in cy:
			var coord = Vector2i(x, y)
			var terrain = Tile.TerrainPlain
			if randf() > 0.3:
				if randf() > 0.7:
					terrain = Tile.TerrainForest
			else:
				terrain = Tile.TerrainWater
			var t = Tile.new(coord, terrain)
			t.resource_type = randi_range(0, 3) + ProductionResource
			t.resource_amount = randi_range(2, 7)
			if terrain == Tile.TerrainPlain || terrain == Tile.TerrainForest:
				if randf() < 0.8:
					for i in randi_range(4, 12):
						var unit = Unit.new("rat")
						t.neutral_units.append(unit)
			map[coord] = t
	for c in map:
		map[c].init_surroundings(map)

	players.clear()
	main_player = add_player(main_player_id)
	var main_player_tile = map[main_player.coord]
	for t in get_surrounding_tiles(main_player_tile):
		if !t.passable:
			t.terrain = Tile.TerrainPlain
			t.passable = true
	for t in get_surrounding_tiles_within(main_player_tile, 2):
		t.neutral_units.clear()
	neutral_player = add_player(neutral_player_id)
	#var ai1 = add_player(1)
	
	techs.clear()
	techs = Technology.load()

func save_game(path : String, hand_data : Array):
	var saving = {
		"round": round,
		"state": state,
		"cx": cx,
		"cy": cy
	}
	var _map = {}
	for c in map:
		var tile = map[c] as Tile
		var _units = tile.get_neutral_unit_types()
		var t = {
			"terrain": tile.terrain,
			"resource_type": tile.resource_type,
			"resource_amount": tile.resource_amount,
			"units": _units
		}
		_map[c] = t
	saving["map"] = _map
	var _players = {}
	for id in players:
		var player = players[id] as Player
		var _buildings = {}
		for c in player.buildings:
			var building = player.buildings[c] as Building
			var b = {
				"name": building.building_name,
				"display_name": building.display_name,
				"description": building.description,
				"ext": building.ext
			}
			_buildings[c] = b
		var _units = []
		for u in player.units:
			_units.append(u.unit_name)
		var _troop_unites = []
		for u in player.troop_units:
			_troop_unites.append(u.unit_name)
		var p = {
			"coord": player.coord,
			"territories": player.territories,
			"buildings": _buildings,
			"vision": player.vision,
			"production": player.production,
			"gold": player.gold,
			"science": player.science,
			"food": player.food,
			"gear": player.gear,
			"avaliable_constructions": player.avaliable_constructions,
			"avaliable_trainings": player.avaliable_trainings,
			"unused_territories": player.unused_territories,
			"units": _units,
			"troop_units": _troop_unites,
			"troop_target": player.troop_target
		}
		_players[id] = p
	saving["players"] = _players
	saving["battle_attacker"] = battle_attacker
	saving["battle_defender"] = battle_defender
	saving["battle_order_list"] = battle_order_list
	saving["hand"] = hand_data
	var json = JSON.stringify(saving, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json)
	file.close()

var loaded_hand_data : Array

func load_game(path : String):
	var json = FileAccess.get_file_as_string(path)
	json = JSON.parse_string(json)
	
	round = json["round"]
	state = json["state"]
	cx = json["cx"]
	cy = json["cy"]

	map.clear()
	var _map = json["map"] as Dictionary
	for c in _map:
		var t = _map[c]
		var tile = Tile.new(str_to_var("Vector2i" + c), t["terrain"])
		tile.resource_type = t["resource_type"]
		tile.resource_amount = t["resource_amount"]
		var unit_types = t["units"]
		for n in unit_types:
			for i in unit_types[n]:
				var unit = Unit.new(n)
				tile.neutral_units.append(unit)
		map[tile.coord] = tile
	for c in map:
		map[c].init_surroundings(map)
	
	players.clear()
	var _players = json["players"] as Dictionary
	for id in _players:
		var p = _players[id]
		var _territories = p["territories"]
		var _buildings = p["buildings"]
		var _vision = p["vision"]
		var _units = p["units"]
		var _troop_units = p["troop_units"]
		var player = Player.new(int(id))
		player.coord = str_to_var("Vector2i" + p["coord"])
		player.production = p["production"]
		player.gold = p["gold"]
		player.science = p["science"]
		player.food = p["food"]
		player.gear = p["gear"]
		player.avaliable_constructions = p["avaliable_constructions"]
		player.avaliable_trainings = p["avaliable_trainings"]
		player.unused_territories = p["unused_territories"]
		player.troop_target = str_to_var("Vector2i" + p["troop_target"])
		for c in _territories:
			player.territories[str_to_var("Vector2i" + c)] = 1
		for c in _buildings:
			var b = _buildings[c]
			var building = Building.new(b["name"])
			building.display_name = b["display_name"]
			building.description = b["description"]
			building.ext = b["ext"]
			player.buildings[str_to_var("Vector2i" + c)] = building
		for c in _vision:
			player.vision[str_to_var("Vector2i" + c)] = 1
		for u in _units:
			var unit = Unit.new(u)
			player.units.append(unit)
		for u in _troop_units:
			var unit = Unit.new(u)
			player.troop_units.append(unit)
		player.calc_troop_mobility()
		players[int(id)] = player
	
	main_player = players[main_player_id]
	neutral_player = players[neutral_player_id]
	
	techs.clear()
	
	battle_attacker = json["battle_attacker"]
	battle_defender = json["battle_defender"]
	battle_order_list = json["battle_order_list"]
	
	loaded_hand_data = json["hand"]

func on_scene_ready():
	if round == 0:
		change_state(Game.PrepareState)
	if state == BattleState:
		battle_player_changed.emit()

func _ready() -> void:
	seed(Time.get_ticks_msec())
