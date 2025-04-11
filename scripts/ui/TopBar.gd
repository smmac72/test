extends Panel

# Отображение верхней панели с информацией о деньгах, репутации и времени

# Компоненты UI
@onready var money_label = $HBoxContainer/MoneyContainer/MoneyLabel
@onready var money_icon = $HBoxContainer/MoneyContainer/MoneyIcon
@onready var reputation_label = $HBoxContainer/ReputationContainer/ReputationLabel
@onready var reputation_icon = $HBoxContainer/ReputationContainer/ReputationIcon
@onready var day_label = $HBoxContainer/DayContainer/DayLabel
@onready var calendar_icon = $HBoxContainer/DayContainer/CalendarIcon
@onready var time_controls = $TimeControls
@onready var radio_player = $RadioPlayer

# Ссылки на другие системы
@onready var game_manager: GameManager = $"/root/GameManager"
@onready var customer_manager: CustomerManager = $"/root/CustomerManager"
@onready var time_manager: TimeManager = $"/root/TimeManager"

func _ready() -> void:
	# Подключаем сигналы
	game_manager.connect("money_changed", _on_money_changed)
	customer_manager.connect("reputation_changed", _on_reputation_changed)
	game_manager.connect("day_changed", _on_day_changed)
	time_manager.connect("hour_passed", _on_hour_passed)
	
	# Инициализируем отображение
	_update_display()
	
	# Показываем элементы управления временем и радио
	time_controls.show()
	radio_player.show()
	
	# Загружаем иконки
	_load_icons()

# Загрузка иконок
func _load_icons() -> void:
	# Загружаем иконки для верхней панели
	var money_icon_path = "res://assets/images/icons/money_icon.png"
	var reputation_icon_path = "res://assets/images/icons/reputation_icon.png"
	var calendar_icon_path = "res://assets/images/icons/calendar_icon.png"
	
	if ResourceLoader.exists(money_icon_path):
		money_icon.texture = load(money_icon_path)
	
	if ResourceLoader.exists(reputation_icon_path):
		reputation_icon.texture = load(reputation_icon_path)
	
	if ResourceLoader.exists(calendar_icon_path):
		calendar_icon.texture = load(calendar_icon_path)

# Обновление отображения
func _update_display() -> void:
	# Обновляем все показатели
	money_label.text = str(game_manager.money) + "₽"
	reputation_label.text = str(int(customer_manager.reputation))
	day_label.text = "День " + str(game_manager.game_day)

# Обработчики сигналов
func _on_money_changed(new_amount: int, change: int, reason: String) -> void:
	money_label.text = str(new_amount) + "₽"
	
	# Анимация изменения денег (мигание цветом)
	var original_color = money_label.modulate
	var target_color = Color.GREEN if change > 0 else Color.RED if change < 0 else original_color
	
	var tween = create_tween()
	tween.tween_property(money_label, "modulate", target_color, 0.2)
	tween.tween_property(money_label, "modulate", original_color, 0.2)

func _on_reputation_changed(new_reputation: float, reason: String) -> void:
	reputation_label.text = str(int(new_reputation))
	
	# Анимация изменения репутации
	var original_color = reputation_label.modulate
	var target_color = Color(0.2, 0.8, 1.0)  # Голубой
	
	var tween = create_tween()
	tween.tween_property(reputation_label, "modulate", target_color, 0.2)
	tween.tween_property(reputation_label, "modulate", original_color, 0.2)

func _on_day_changed(new_day: int) -> void:
	day_label.text = "День " + str(new_day)
	
	# Анимация смены дня
	var original_color = day_label.modulate
	var target_color = Color(1.0, 0.8, 0.2)  # Желтый
	
	var tween = create_tween()
	tween.tween_property(day_label, "modulate", target_color, 0.3)
	tween.tween_property(day_label, "modulate", original_color, 0.3)

func _on_hour_passed(game_time: Dictionary) -> void:
	# Обновляем отображение времени, если нужно
	# Например, можно добавить часы в верхнюю панель
	pass
