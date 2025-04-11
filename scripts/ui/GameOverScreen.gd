class_name GameOverScreen
extends Panel

# Сигналы
signal retry_requested
signal quit_requested

# Компоненты
@onready var title_label: Label = $TitleLabel
@onready var reason_label: Label = $ReasonLabel
@onready var stats_label: Label = $StatsLabel
@onready var retry_button: Button = $RetryButton
@onready var quit_button: Button = $QuitButton

# Данные окончания игры
var game_over_reason: String = ""
var game_stats: Dictionary = {}

func _ready() -> void:
	# Подключаем сигналы кнопок
	retry_button.connect("pressed", _on_retry_button_pressed)
	quit_button.connect("pressed", _on_quit_button_pressed)
	
	# Настраиваем внешний вид
	var style = get_theme_stylebox("panel", "Panel").duplicate()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	add_theme_stylebox_override("panel", style)

# Настройка экрана
func setup(reason: String, stats: Dictionary) -> void:
	game_over_reason = reason
	game_stats = stats
	
	# Заполняем данные
	title_label.text = "Конец игры"
	reason_label.text = reason
	
	# Формируем текст статистики
	var stats_text = "Статистика:\n"
	stats_text += "Количество дней: " + str(stats.get("day", 0)) + "\n"
	stats_text += "Итоговый капитал: " + str(stats.get("money", 0)) + "₽"
	
	stats_label.text = stats_text

# Обработчики кнопок
func _on_retry_button_pressed() -> void:
	# Начинаем новую игру
	var game_manager = $"/root/GameManager"
	game_manager.start_new_game()
	queue_free()

func _on_quit_button_pressed() -> void:
	# Выходим в главное меню
	get_tree().change_scene_to_file("res://scenes/global/MainMenu.tscn")
	queue_free()

# Показ экрана
func popup_centered() -> void:
	# Центрируем экран
	var viewport_size = get_viewport_rect().size
	var panel_size = size
	position = (viewport_size - panel_size) / 2
	
	# Показываем
	show()
