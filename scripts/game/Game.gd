class_name Game
extends Node

# Компоненты главной сцены
@onready var loading_screen: Control = $LoadingScreen
@onready var main_ui: Control = $MainUI
@onready var production_ui: ProductionUI = $MainUI/VSplitContainer/ContentContainer/ProductionUI
@onready var shop_ui: ShopUI = $MainUI/VSplitContainer/ContentContainer/ShopUI
@onready var top_bar: Panel = $MainUI/VSplitContainer/TopBar

# Индикаторы
@onready var money_label: Label = $MainUI/VSplitContainer/TopBar/HBoxContainer/MoneyContainer/MoneyLabel
@onready var reputation_label: Label = $MainUI/VSplitContainer/TopBar/HBoxContainer/ReputationContainer/ReputationLabel
@onready var day_label: Label = $MainUI/VSplitContainer/TopBar/HBoxContainer/DayContainer/DayLabel

# Ссылки на менеджеры
@onready var config_manager: ConfigManager = $"/root/ConfigManager"
@onready var game_manager: GameManager = $"/root/GameManager"
@onready var production_manager: ProductionManager = $"/root/ProductionManager"
@onready var customer_manager: CustomerManager = $"/root/CustomerManager"
@onready var time_manager: TimeManager = $"/root/TimeManager"
@onready var event_manager: EventManager = $"/root/EventManager"
@onready var audio_manager: AudioManager = $"/root/AudioManager"

# Переменные сцены
var loading_completed: bool = false
var tutorial_shown: bool = false

func _ready() -> void:
	# Показываем экран загрузки
	loading_screen.show()
	main_ui.hide()
	
	# Подключаем сигналы
	game_manager.connect("money_changed", _on_money_changed)
	game_manager.connect("reputation_changed", _on_reputation_changed)
	game_manager.connect("day_changed", _on_day_changed)
	
	# Запускаем загрузку
	call_deferred("start_loading")

# Запуск загрузки
func start_loading() -> void:
	# Начинаем асинхронную загрузку ресурсов
	await get_tree().create_timer(0.5).timeout
	
	# Дожидаемся загрузки конфигураций
	if not config_manager.is_loaded:
		await config_manager.configs_loaded
	
	# Инициализируем системы
	initialize_systems()
	
	# Завершение загрузки
	complete_loading()

# Инициализация игровых систем
func initialize_systems() -> void:
	# Инициализируем UI
	production_ui.current_production_type = "samogon"  # Начинаем с самогона
	production_ui.update_production_ui()
	
	# Инициализируем магазин
	shop_ui.initialize()
	
	# Инициализируем менеджер времени
	time_manager.set_time_scale(1.0)
	time_manager.set_paused(false)
	
	# Обновляем UI с текущими значениями
	update_ui_values()

# Завершение загрузки
func complete_loading() -> void:
	# Скрываем экран загрузки
	loading_screen.hide()
	main_ui.show()
	
	# Отмечаем загрузку как завершенную
	loading_completed = true
	
	# Запускаем фоновую музыку
	if audio_manager:
		audio_manager.play_music("game_theme")
	
	# Если это новая игра, показываем обучение
	if game_manager.is_new_game and not tutorial_shown:
		show_tutorial()

# Показ обучения
func show_tutorial() -> void:
	# Создаем систему обучения
	var tutorial = preload("res://scenes/ui/TutorialSystem.tscn").instantiate()
	add_child(tutorial)
	
	# Запускаем обучение
	tutorial.start_tutorial()
	
	# Отмечаем, что обучение показано
	tutorial_shown = true

# Обновление значений UI
func update_ui_values() -> void:
	# Обновляем индикаторы
	money_label.text = str(game_manager.money) + "₽"
	reputation_label.text = str(int(customer_manager.reputation))
	day_label.text = "День " + str(game_manager.game_day)

# Обработчики сигналов
func _on_money_changed(new_amount: int, change: int, reason: String) -> void:
	# Обновляем индикатор денег
	money_label.text = str(new_amount) + "₽"
	
	# Показываем уведомление об изменении, если есть причина
	if not reason.is_empty():
		var change_text = str(change) + "₽"
		if change > 0:
			change_text = "+" + change_text
		show_notification(reason + ": " + change_text)

func _on_reputation_changed(new_reputation: float, change: float, reason: String) -> void:
	# Обновляем индикатор репутации
	reputation_label.text = str(int(new_reputation))
	
	# Показываем уведомление об изменении, если есть причина
	if not reason.is_empty() and abs(change) > 0.1:
		var change_text = str(stepify(change, 0.1))
		if change > 0:
			change_text = "+" + change_text
		show_notification(reason + ": " + change_text + " к репутации")

func _on_day_changed(new_day: int) -> void:
	# Обновляем индикатор дня
	day_label.text = "День " + str(new_day)
	
	# Показываем уведомление о новом дне
	show_notification("Начался день " + str(new_day))

# Переключение режима производства
func _on_production_mode_changed(mode: String) -> void:
	# Проверяем доступность режима
	if game_manager.production_levels.get(mode, 0) <= 0:
		# Режим недоступен, нужно его купить
		show_upgrade_menu(mode)
		return
	
	# Меняем режим и обновляем UI
	production_ui.current_production_type = mode
	production_ui.update_production_ui()
	
	# Воспроизводим звук
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)

# Показ меню покупки улучшения
func show_upgrade_menu(production_type: String) -> void:
	var upgrade_menu = preload("res://scenes/ui/UpgradeMenu.tscn").instantiate()
	upgrade_menu.filter_by_type(production_type)
	upgrade_menu.connect("upgrade_selected", _on_upgrade_selected)
	add_child(upgrade_menu)
	upgrade_menu.popup_centered()

# Обработчик выбора улучшения
func _on_upgrade_selected(upgrade_id: String) -> void:
	# Поиск данных улучшения
	var upgrade_data = null
	var production_type = ""
	
	# Находим данные улучшения
	for type in config_manager.upgrades:
		for level in config_manager.upgrades[type]:
			var upgrade = config_manager.upgrades[type][level]
			if upgrade.id == upgrade_id:
				upgrade_data = upgrade
				production_type = type
				break
	
	if upgrade_data:
		# Покупаем улучшение
		var success = game_manager.purchase_upgrade(production_type, upgrade_data.level)
		
		if success:
			# Переключаемся на новый режим
			production_ui.current_production_type = production_type
			production_ui.update_production_ui()
			
			# Показываем уведомление
			show_notification("Приобретено улучшение: " + upgrade_data.name)
		else:
			# Показываем уведомление об ошибке
			show_notification("Недостаточно денег для покупки улучшения!")

# Показ временного уведомления
func show_notification(text: String) -> void:
	var notification = preload("res://scenes/ui/Notification.tscn").instantiate()
	notification.setup(text)
	add_child(notification)
	
	# Воспроизводим звук
	if audio_manager:
		audio_manager.play_sound("popup_open", AudioManager.SoundType.UI)
