extends TextureRect
class_name Card

var item_data: Dictionary

func set_item(data: Dictionary) -> void:
	item_data = data
	$Label.text = data.get("name", "")
	texture = load("res://art/%s.png" % data.get("sprite", "placeholder"))

func _get_drag_data(_pos):
	var preview := duplicate() as TextureRect
	preview.self_modulate.a = 0.7
	set_drag_preview(preview)
	return self
