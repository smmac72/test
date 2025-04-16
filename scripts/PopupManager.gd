extends CanvasLayer

func show_message(text:String, duration:float=3.0):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1,1,0))
	add_child(label)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 0.1
	label.anchor_bottom = 0.1
	label.set_position(Vector2(0,0))
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0, duration).set_trans(Tween.TRANS_SINE)
	tween.connect("finished", Callable(label,"queue_free"))
