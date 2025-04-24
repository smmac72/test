extends Control

@onready var btn_continue: Button = $ColorRect/HBoxContainer/Button_continue
@onready var btn_start: Button = $ColorRect/HBoxContainer/Button_start
@onready var btn_options: Button = $ColorRect/HBoxContainer/Button_options
@onready var btn_exit: Button = $ColorRect/HBoxContainer/Button_exit
@onready var imgs: Array [Sprite2D] = [$Water,$Koji,$Sugar,$Rice,$Raspberry,$Moonshine]
@onready var mus = $LunarBrew
var time: float = 0.0
var amplitude: float = 30.0  # Амплитуда движения (в пикселях)
var frequency: float = 1.0   # Частота колебаний
var base_positions: Array = []
func _ready() -> void:
	mus.play()
	base_positions = []
	for img in imgs:
		base_positions.append(img.position)
	btn_exit.pressed.connect(_exit)
	btn_start.pressed.connect(_new_game)
	
func _exit () ->void:
	get_tree().quit() 

func _new_game ()->void:
	#$UiClick.play()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
func _process(delta: float) -> void:
	time += delta
	for i in imgs.size():
		var sprite = imgs[i]
		var base_pos = base_positions[i]
		var direction = sprite.scale.x  # Считаем, что направление отражено в scale.x: 1 или -1
		var offset = sin(time * frequency + i) * amplitude  # Сдвиг синусоиды со смещением по i
		sprite.position = base_pos + Vector2(sin(sprite.rotation)*direction * offset,cos(sprite.rotation)*direction * offset)
