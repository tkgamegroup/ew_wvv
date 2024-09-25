extends Camera2D

var move_sp = Vector2(0, 0)
var tween : Tween = null

func move_to(target : Vector2):
	if tween:
		tween.kill()
		tween = null
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", target, 0.15)
	tween.tween_callback(func():
		tween = null
	)

func _process(delta: float) -> void:
	if !tween:
		if move_sp.x != 0 || move_sp.y != 0:
			position += move_sp / zoom.x
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_scroll_down"):
		var v = max(zoom.x - 0.3, 0.4)
		zoom = Vector2(v, v)
	if event.is_action_pressed("mouse_scroll_up"):
		var v = min(zoom.x + 0.3, 5)
		zoom = Vector2(v, v)
	
	if event is InputEventMouseMotion:
		move_sp = Vector2(0, 0)
		var threshold = 20
		var vp = get_viewport()
		var vp_size = vp.size
		var mouse_pos = vp.get_mouse_position()
		if mouse_pos.x >= 0 && mouse_pos.y >= 0 && mouse_pos.x <= vp_size.x && mouse_pos.y <= vp_size.y:
			if mouse_pos.x < threshold:
				move_sp = Vector2(-5, 0)
			elif mouse_pos.x > vp_size.x - threshold:
				move_sp = Vector2(+5, 0)
			if mouse_pos.y < threshold:
				move_sp = Vector2(0, -5)
			elif mouse_pos.y > vp_size.y - threshold:
				move_sp = Vector2(0, +5)
