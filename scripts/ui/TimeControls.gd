class_name TimeControls
extends Control

# Сигналы
signal time_scale_changed(scale)
signal pause_toggled(is_paused)

# Компоненты
@onready var pause_button: Button = $PauseButton
@onready var play_button: Button = $PlayButton
@onready var fast_button: Button = $FastButton
@onready var ultrafast_button: Button = $UltrafastButton

# Текущая скорость
var current_scale: float = 1.0
var is_paused: bool = false

func _ready() -> void:
	# Подключаем сигналы
	pause_button.connect("pressed", _on_pause_button_pressed)
	play_button.connect("pressed", _on_play_button_pressed)
	fast_button.connect("pressed", _on_fast_button_pressed)
	ultrafast_button.connect("pressed", _on_ultrafast_button_pressed)
	
	# Начальное состояние
	update_button_states()

# Обновление состояния кнопок
func update_button_states() -> void:
	pause_button.disabled = is_paused
	play_button.disabled = not is_paused and current_scale == 1.0
	fast_button.disabled = not is_paused and current_scale == 2.0
	ultrafast_button.disabled = not is_paused and current_scale == 5.0

# Обработчики кнопок
func _on_pause_button_pressed() -> void:
	is_paused = true
	emit_signal("pause_toggled", is_paused)
	update_button_states()

func _on_play_button_pressed() -> void:
	is_paused = false
	current_scale = 1.0
	emit_signal("time_scale_changed", current_scale)
	emit_signal("pause_toggled", is_paused)
	update_button_states()

func _on_fast_button_pressed() -> void:
	is_paused = false
	current_scale = 2.0
	emit_signal("time_scale_changed", current_scale)
	emit_signal("pause_toggled", is_paused)
	update_button_states()

func _on_ultrafast_button_pressed() -> void:
	is_paused = false
	current_scale = 5.0
	emit_signal("time_scale_changed", current_scale)
	emit_signal("pause_toggled", is_paused)
	update_button_states()
