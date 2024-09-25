extends CheckButton

var is_on : bool = false
var anim_time : float = -1.0
signal mode_changed(v : bool)

func _ready() -> void:
	toggled.connect(func(_on):
		is_on = _on
		anim_time = 0.0
		mode_changed.emit(is_on)
	)

func _process(delta: float) -> void:
	if is_on:
		anim_time += delta
		var v = 1.0 - (sin(deg_to_rad(anim_time * 360.0)) + 1.0) / 4.0
		modulate = Color(v, v, v, 1)
	else:
		if anim_time >= 0.0:
			anim_time = -1.0
			modulate = Color(1, 1, 1, 1)
