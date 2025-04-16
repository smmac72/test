extends Panel
class_name Slot

@export var accepted_type: String = ""
@export var required: bool = true
var contained_card: Card

func _can_drop_data(_pos, data) -> bool:
	return data is Card and contained_card == null and _accepts(data)

func _drop_data(_pos, data):
	if data is Card and _accepts(data):
		contained_card = data
		data.reparent(self)
		data.position = Vector2()

func _accepts(card: Card) -> bool:
	return accepted_type == "" or accepted_type == card.item_data.get("type","")
