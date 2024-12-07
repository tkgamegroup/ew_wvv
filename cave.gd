extends Object

class_name Cave

var name : String
var cx : int = 21
var cy : int = 20
var target_score : int
var collapse_turn : int
var durability : int = 30
var base_damage_per_turn : int = 10
var current_damage : int
var reinforcement : int = 0
var selector : Control

func calc_damage():
	if Game.turn < 3:
		current_damage = base_damage_per_turn
	elif Game.turn < 6:
		current_damage = base_damage_per_turn * 2
	else:
		current_damage = base_damage_per_turn * int(pow(2.0, Game.turn - 6 + 2))
