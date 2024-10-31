extends Control

func on_exit() -> void:
	get_tree().quit()

func on_continue() -> void:
	Game.load_game("res://savings/auto_save.txt")
	get_tree().change_scene_to_file("res://main.tscn")

func on_new_game() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
	Game.start_new_game({"cx": 20, "cy": 10})
