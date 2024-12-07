extends Control

var cards : Array[Card]
var draw_pile : Array[Card]
var discard_pile : Array[Card]

signal clicked

@onready var rect = $Rect

func add_card(card : Card):
	cards.append(card)

func draw() -> Card:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return
		for c in discard_pile:
			draw_pile.append(c)
		discard_pile.clear()
		draw_pile.shuffle()
	var card = draw_pile[0]
	draw_pile.remove_at(0)
	return card

func reset():
	draw_pile.clear()
	discard_pile.clear()
	for c in cards:
		draw_pile.append(c)
	draw_pile.shuffle()

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var wtf = rect.get_global_rect()
			if rect.get_rect().has_point(event.position):
				if event.pressed:
					clicked.emit()
