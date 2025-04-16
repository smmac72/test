class_name Notification
extends Control

# Компоненты
@onready var background: Panel = $Background
@onready var message_label: Label = $Background/MessageLabel
@onready var timer: Timer = $Timer

# Настройки
var duration: float = 3.0  # Время показа уведомления

func _ready() -> void:
	# Подключаем таймер
	timer.wait_time = duration
	timer.one_shot = true
	timer.connect("timeout", _on_timer_timeout)
	
	# Запускаем анимацию появления
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Запускаем таймер
	timer.start()
	
	

# Настройка уведомления
func setup(text: String, time: float = 3.0) -> void:
	message_label.text = text
	duration = time
	
	# Адаптируем размер панели
	var min_width = 300
	var text_width = message_label.get_font("font").get_string_size(text).x
	background.custom_minimum_size.x = max(min_width, text_width + 40)  # 20px отступ с каждой стороны

# Обработчик таймера
func _on_timer_timeout() -> void:
	# Анимация исчезновения
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
