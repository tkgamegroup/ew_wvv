extends Control

var draw_pile : Array[Card]
var discard_pile : Array[Card]

signal clicked

@onready var rect = $Rect

func add_card(card : Card):
	draw_pile.append(card)

func draw() -> Card:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return
		for c in discard_pile:
			draw_pile.append(c)
		draw_pile.shuffle()
		discard_pile.clear()
	var card = draw_pile[0]
	draw_pile.remove_at(0)
	return card

func shuffle():
	draw_pile.shuffle()

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var wtf = rect.get_global_rect()
			if rect.get_rect().has_point(event.position):
				if event.pressed:
					clicked.emit()
