extends Panel
class_name Slot

@export var accepted_type: String = ""
@export var required: bool = true
@export var display_name: String = ""
var contained_card: Card = null
@onready var drop_sound: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var drop_bottle: AudioStreamPlayer = AudioStreamPlayer.new()
signal card_placed(card: Card)
signal card_removed(card: Card)

func _ready():
	drop_sound.stream= load("res://Sound/place_card.mp3")
	drop_sound.bus = "&Sfx"
	drop_bottle.stream= load("res://Sound/place_bottle.mp3")
	drop_bottle.bus = "&Sfx"
	# Добавляем метку, чтобы показывать, что это за слот
	if display_name != "":
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.text = display_name
		label.custom_minimum_size = Vector2(0, 15)
		label.position += Vector2(2, 5)
		label.add_theme_font_size_override("font_size", 12)
		add_child(label)

func _can_drop_data(_pos, data) -> bool:
	if data is Card:
		var type_match = accepted_type == "" or data.item_data.get("type", "") == accepted_type
		return contained_card == null and type_match
	return false

func _drop_data(_pos, data):
	if data is Card and _accepts(data):
		data.dragging = false
		if contained_card != null:
			remove_card()
		if data.get_type() != "final_product":
			get_tree().get_current_scene().add_child(drop_sound)
			drop_sound.play()
		else:
			get_tree().get_current_scene().add_child(drop_bottle)
			drop_bottle.play()			
		set_card(data)
		card_placed.emit(data)

func set_card(card: Card) -> void:
	contained_card = card
	if card.get_parent():
		card.reparent(self)
	else:
		add_child(card)
	card.position = Vector2.ZERO
	card.size = size * 1 # Немного меньше слота

func remove_card() -> Card:
	if contained_card == null:
		return null
		
	var card = contained_card
	contained_card = null
	card_removed.emit(card)
	
	return card

func _accepts(card: Card) -> bool:
	return accepted_type == "" or accepted_type == card.item_data.get("type", "")

func highlight_valid():
	self_modulate = Color(0.5, 1.0, 0.5, 1.0)  # Зеленый, если слот может принять карту

func highlight_invalid():
	self_modulate = Color(1.0, 0.5, 0.5, 1.0)  # Красный, если слот не может принять карту

func reset_highlight():
	self_modulate = Color(0.35, 0.25, 0, 1.0)  # Обычный цвет
