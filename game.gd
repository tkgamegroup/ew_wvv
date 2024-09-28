extends Node2D

const Tile = preload("res://tile.gd")
const Player = preload("res://player.gd")

enum
{
	StatePrepare,
	StateBattle
}

const cx = 20
const cy = 10

var map : Dictionary
var players : Dictionary
var techs : Dictionary
var state : int = 0
signal state_changed
signal attack_commited

var hovering_tile = Vector2i(-1, -1)

var battle_attacker : int = -1
var battle_defender : int = -1
var battle_order_list : Array
signal battle_player_changed

func add_player(id : int):
	var cands = []
	for c in map:
		if c.x > 3 && c.x < Game.cx - 4 && c.y > 3 && c.y < Game.cy - 4:
			var t = map[c] as Tile
			if t.player == -1 && t.terrain == Tile.TerrainPlain && t.neutral_units.is_empty():
				cands.append(t)
	var coord = cands.pick_random().coord
	
	var player = Player.new(id)
	player.coord = coord
	player.add_territory(coord)
	player.add_building(coord, "city")
	players[id] = player
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
	
func find_path_on_map(start : Vector2i, end : Vector2i):
	var ret = []
	var start_tile = map[start]
	if start.x == end.x && start.y == end.y:
		ret.append(start_tile)
		return ret
	var end_tile = map[end]
	var dict = {}
	var d = 1
	var found = false
	while true:
		var surroundings = get_surrounding_tiles_within(start_tile, d)
		for t in surroundings:
			if !dict.has(t):
				dict[t] = d
			if t == end_tile:
				found = true
				break
		if found:
			break
		d += 1
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
	if state == StatePrepare:
		for id in players:
			var player = players[id] as Player
			player.on_state()
	elif state == StateBattle:
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
		if !player.units.is_empty():
			battle_attacker = id
			break
		if idx == start_idx:
			break
	if battle_attacker != -1 && battle_attacker != 0:
		# AI出兵
		var attacker_player = players[battle_attacker] as Player
		var num = randi_range(1, attacker_player.units.size())
		for i in num:
			var unit_name = attacker_player.units.pick_random()
			attacker_player.move_unit_to_troop(unit_name)
		var cands = {}
		for c in attacker_player.territories:
			for t in get_surrounding_tiles_within(map[c], attacker_player.troop_mobility):
				if t.player == 0:
					if !cands.has(t.coord):
						cands[t.coord] = c
		if !cands.is_empty():
			var c = cands.keys().pick_random()
			attacker_player.troop_target = c
			attacker_player.troop_path = find_path_on_map(cands[c], c)
			var target_tile = map[c] as Tile
			if target_tile.player != -1:
				battle_defender = target_tile.player
		
	battle_player_changed.emit()
		
func commit_attack():
	if battle_attacker == -1:
		return
	if battle_attacker == 0:
		var attacker_player = players[battle_attacker] as Player
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
			ret.append(u.unit_name)
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
		var unit = Unit.new(u)
		attacker_units.append(unit)
	
	attacker_player.troop_units.clear()
	attacker_player.troop_target = Vector2i(-1, -1)
	attacker_player.troop_mobility = 0
	attacker_player.troop_path.clear()
	
	if target_tile.player == -1:
		for u in target_tile.neutral_units:
			var unit = Unit.new(u)
			defender_units.append(unit)
	else:
		var defender_player = players[target_tile.player] as Player
		for u in defender_player.troop_units:
			var unit = Unit.new(u)
			defender_units.append(unit)
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
	
	if !battle_calc_callback.is_valid():
		next_attacker()

func _ready() -> void:
	seed(Time.get_ticks_msec())
	
	techs = Technology.load()
	
	for x in cx:
		for y in cy:
			var c = Vector2i(x, y)
			var t = Tile.new(c)
			if randf() > 0.3:
				if randf() > 0.3:
					t.terrain = Tile.TerrainPlain
				else:
					t.terrain = Tile.TerrainForest
			else:
				t.terrain = Tile.TerrainWater
			if randf() < 0.3:
				for i in randi_range(0, 5):
					t.neutral_units.append("bear")
			t.production_resource = randi_range(4, 9)
			map[c] = t
			
	for c in map:
		map[c].init_surroundings(map)
	
	var main_player = add_player(0)
	var ai1 = add_player(1)

func _process(delta: float) -> void:
	pass
