extends Control

var hand_width = 950
const gap0 = -5
const y_off = +5
const max_angle = 5
const max_y = 15
@export var y_curve : Curve
@export var angle_curve : Curve

func get_card_pos(idx : int):
	var n = get_child_count()
	if idx == -1:
		idx = n - 1
	var x_off = 0
	var gap = gap0
	var cards_w = Game.card_width * n + gap0 * (n - 1)
	if cards_w <= hand_width:
		x_off = (hand_width - cards_w) / 2
	else:
		gap = (hand_width - Game.card_width * n) / (n - 1 if n > 1 else 1)
	return  Vector2(x_off + idx * (Game.card_width + gap), y_off)

func _ready() -> void:
	hand_width = size.x

func _process(delta: float) -> void:
	var n = get_child_count()
	if n == 0:
		return
	var x_off = 0
	var gap = gap0
	var cards_w = Game.card_width * n + gap0 * (n - 1)
	if cards_w <= hand_width:
		x_off = (hand_width - cards_w) / 2
	else:
		gap = (hand_width - Game.card_width * n) / (n - 1 if n > 1 else 1)
	for i in n:
		var card : Card = get_child(i)
		var u = float(i) / float(n - 1) if n > 1 else 0.5
		var y = -y_curve.sample(u) * max_y + sin((u + Time.get_ticks_msec() * 0.0000005 * min(hand_width, cards_w)) * 2.0 * PI) * 4
		var a = (angle_curve.sample(u) * 2.0 - 1.0) * max_angle
		if !card.lock && !card.dragging:
			card.position = lerp(card.position, Vector2(x_off, y_off + y), 0.2)
			card.rotation_degrees  = lerp(card.rotation_degrees , a, 0.2)
			x_off += Game.card_width + gap
