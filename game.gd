extends Node2D

const Tile = preload("res://tile.gd")
const Player = preload("res://player.gd")

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
	GeerResource
}

const cx = 20
const cy = 10

var map : Dictionary
var players : Dictionary
var techs : Dictionary
var turn : int = 0
var state : int = 0
const main_player_id = 0
const neutral_player_id = 255
var main_player : Player = null
var neutral_player : Player = null
signal state_changed
signal attack_commited

var hovering_tile = Vector2i(-1, -1)

var battle_attacker : int = -1
var battle_defender : int = -1
var battle_order_list : Array
signal battle_player_changed

var peeding_neutral_attacks : Dictionary

func get_shuffled_indices(n : int):
	var ret = []
	for i in n:
		ret.append(i)
	ret.shuffle()
	return ret

func add_player(id : int):
	var cands = []
	if id == neutral_player_id:
		cands.append(map[Vector2i(0, 0)])
	else:
		for c in map:
			if c.x > 3 && c.x < Game.cx - 4 && c.y > 3 && c.y < Game.cy - 4:
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
	for t in get_surrounding_tiles(tile):
		t.neutral_units.clear()
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
	
func find_path_on_map(start : Vector2i, end : Vector2i, vision : Dictionary):
	var ret = []
	var start_tile = map[start]
	if start.x == end.x && start.y == end.y:
		ret.append(start_tile)
		return ret
	var end_tile = map[end]
	var dict = {}
	var d = 1
	var max_d = max(Game.cx, Game.cy)
	var found = false
	while true:
		var surroundings = get_surrounding_tiles_within(start_tile, d)
		for t in surroundings:
			if !t.passable:
				continue
			if !vision.is_empty() && !vision.has(t.coord):
				continue
			if !dict.has(t):
				dict[t] = d
			if t == end_tile:
				found = true
				break
		if found:
			break
		d += 1
		if d > max_d:
			return []
	ret.append(end_tile)
	found = false
	var reverse_loop = false
	while true:
		var t = ret[0]
		var _d = dict[t]
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
			if dict.has(_t) && dict[_t] == _d - 1:
				ret.push_front(_t)
				break
		if found:
			break
	ret.push_front(start_tile)
	return ret
	
func change_state(new_state : int) :
	state = new_state
	if state == PrepareState:
		turn += 1
		
		peeding_neutral_attacks.clear()
		for c in map:
			var tile = map[c] as Tile
			if !tile.neutral_units.is_empty():
				var types = {}
				for n in tile.neutral_units:
					if types.has(n):
						types[n] += 1
					else:
						types[n] = 1
				tile.neutral_units.clear()
				for n in types:
					var size = types[n]
					size += int(size * 0.1)
					for i in size:
						tile.neutral_units.append(n)
				if tile.neutral_units.size() > 20:
					var cands = []
					for t in get_surrounding_tiles(tile):
						if t.player == Game.main_player_id && t.passable:
							cands.append(t)
					if !cands.is_empty():
						peeding_neutral_attacks[tile] = cands.pick_random()

		for id in players:
			var player = players[id] as Player
			player.on_state()
	elif state == BattleState:
		for id in players:
			var player = players[id] as Player
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
	
func next_attacker():
	var start_idx = battle_order_list.find(battle_attacker)
	if start_idx == -1:
		start_idx = 1
	battle_attacker = -1
	battle_defender = -1
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
		var player = players[id] as Player
		if id == main_player_id || (id == neutral_player_id && !peeding_neutral_attacks.is_empty()) || !player.units.is_empty():
			battle_attacker = id
			break
		if idx == start_idx:
			break
	if battle_attacker != -1 && battle_attacker != main_player_id:
		if battle_attacker == neutral_player_id:
			for start in peeding_neutral_attacks:
				var num = start.neutral_units.size() / 2
				for i in num:
					var j = randi_range(0, num - 1)
					neutral_player.troop_units.append(start.neutral_units[j])
					start.neutral_units.remove_at(j)
				var end = peeding_neutral_attacks[start]
				neutral_player.troop_target = end.coord
				neutral_player.troop_path = [start, end]
				peeding_neutral_attacks.erase(start)
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
	var attacker_player = players[battle_attacker] as Player
	var need_food = attacker_player.get_troop_need_food()
	attacker_player.add_food(-need_food)
	
	if battle_attacker == Game.main_player_id:
		var target_tile = map[attacker_player.troop_target] as Tile
		if target_tile.player != -1 && target_tile.player != 0:
			battle_defender = target_tile.player
			var defender_player = players[battle_defender] as Player
			# 根据攻击方的单位数量，AI给出一个猜测
			var num = min(defender_player.units.size(), attacker_player.troop_units.size() + randi_range(-3, +3))
			num = 1 # 测试
			for i in num:
				var unit_name = defender_player.units.pick_random()
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
				if target_tile.production_resource > 0:
					var processed = false
					if battle_calc_callback.is_valid():
						var data = {}
						data.value = target_tile.production_resource
						data.coord = target_tile.coord
						if battle_calc_callback.call("production", data):
							processed = true
					if !processed:
						attacker_player.add_production(target_tile.production_resource)
					target_tile.production_resource = 0
		else:
			var defender_player = players[target_tile.player] as Player
			defender_player.remove_building(target_tile.coord)
	
	if !battle_calc_callback.is_valid():
		next_attacker()

func _ready() -> void:
	seed(Time.get_ticks_msec())
	
	techs = Technology.load()
	
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
			t.production_resource = randi_range(4, 9)
			if terrain == Tile.TerrainPlain || terrain == Tile.TerrainForest:
				if randf() < 0.3:
					for i in randi_range(15, 25):
						var unit = Unit.new("bear")
						t.neutral_units.append(unit)
			map[coord] = t
			
	for c in map:
		map[c].init_surroundings(map)
	
	main_player = add_player(main_player_id)
	neutral_player = add_player(neutral_player_id)
	#var ai1 = add_player(1)
