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
var ui_layer: Control

func _ready() -> void:
	# Добавляем сцену в группу для доступа к UI слою
	add_to_group("ui_layer")
	ui_layer = self
	
	# Показываем экран загрузки
	loading_screen.show()
	main_ui.hide()
	
	# Подключаем сигналы
	game_manager.connect("money_changed", _on_money_changed)
	game_manager.connect("reputation_changed", _on_reputation_changed)
	game_manager.connect("day_changed", _on_day_changed)
	game_manager.connect("game_initialized", _on_game_initialized)
	game_manager.connect("game_over", _on_game_over)
	
	customer_manager.connect("customer_arrived", _on_customer_arrived)
	customer_manager.connect("customer_left", _on_customer_left)
	customer_manager.connect("reputation_changed", _on_reputation_changed)
	
	time_manager.connect("time_of_day_changed", _on_time_of_day_changed)
	time_manager.connect("day_passed", _on_day_passed)
	
	production_manager.connect("recipe_completed", _on_recipe_completed)
	production_manager.connect("product_count_changed", _on_product_count_changed)
	
	# Настраиваем контроль времени
	var time_controls = top_bar.get_node("TimeControls")
	if time_controls:
		time_controls.connect("time_scale_changed", _on_time_scale_changed)
		time_controls.connect("pause_toggled", _on_pause_toggled)
	
	# Запускаем загрузку
	call_deferred("start_loading")

# Запуск загрузки
func start_loading() -> void:
	# Начинаем асинхронную загрузку ресурсов
	await get_tree().create_timer(0.5).timeout
	
	# Дожидаемся загрузки конфигураций
	if not config_manager.is_loaded:
		await config_manager.configs_loaded
	
	# Дожидаемся инициализации GameManager
	if not game_manager.is_initialized:
		await game_manager.game_initialized
	
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
	
	# Запускаем генерацию клиентов
	customer_manager.start_customer_generation()
	
	# Обновляем UI с текущими значениями
	update_ui_values()
	
	# Запускаем фоновую музыку, если ее еще нет
	if audio_manager and not audio_manager.is_music_playing():
		audio_manager.play_music("game_theme")
		
	# Воспроизводим звук окружения в зависимости от времени суток
	if audio_manager:
		audio_manager.play_ambient_for_time_of_day(time_manager.time_of_day_name)

# Завершение загрузки
func complete_loading() -> void:
	# Скрываем экран загрузки
	loading_screen.hide()
	main_ui.show()
	
	# Отмечаем загрузку как завершенную
	loading_completed = true
	
	# Если это новая игра, показываем обучение
	if game_manager.is_new_game and not tutorial_shown and not game_manager.settings.get("tutorial_completed", false):
		show_tutorial()
	
	# Сохраняем игру после загрузки
	game_manager.save_game()

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
func _on_game_initialized() -> void:
	# Обновляем интерфейс после инициализации
	update_ui_values()

func _on_money_changed(new_amount: int, change: int, reason: String) -> void:
	# Обновляем индикатор денег
	money_label.text = str(new_amount) + "₽"
	
	# Показываем уведомление об изменении, если есть причина
	if not reason.is_empty():
		var change_text = str(change) + "₽"
		if change > 0:
			change_text = "+" + change_text
		show_notification(reason + ": " + change_text)

func _on_reputation_changed(new_reputation: float, change_reason: String = "") -> void:
	# Обновляем индикатор репутации
	reputation_label.text = str(int(new_reputation))
	
	# Показываем уведомление об изменении, если есть причина
	if not change_reason.is_empty():
		show_notification(change_reason + ": изменение репутации")

func _on_day_changed(new_day: int) -> void:
	# Обновляем индикатор дня
	day_label.text = "День " + str(new_day)
	
	# Показываем уведомление о новом дне
	show_notification("Начался день " + str(new_day))

func _on_day_passed(game_date: Dictionary) -> void:
	# Дополнительная обработка окончания дня, если нужно
	pass

func _on_time_of_day_changed(new_time: String) -> void:
	# Обработка изменения времени суток
	show_notification("Наступило время суток: " + new_time)
	
	# Обновляем звуки окружения
	if audio_manager:
		audio_manager.play_ambient_for_time_of_day(new_time)

func _on_customer_arrived(customer_data: Dictionary) -> void:
	# Обработка прибытия клиента
	show_notification("Прибыл новый клиент!")

func _on_customer_left(customer_id: String, satisfied: bool) -> void {
	# Обработка ухода клиента
	if satisfied:
		show_notification("Клиент ушел довольный")
	else:
		show_notification("Клиент ушел недовольный")
}

func _on_recipe_completed(product_id: String, quality: int) -> void {
	# Обработка завершения создания продукта
	var product = production_manager.get_product(product_id)
	if product:
		show_notification("Создан: " + product.name + " (качество: " + str(quality) + ")")
}

func _on_product_count_changed(product_id: String, new_count: int, is_ingredient: bool) -> void {
	# Обработка изменения количества продукта/ингредиента
	# Здесь можно добавить логику для обновления UI элементов
}

func _on_time_scale_changed(scale: float) -> void {
	# Обновляем скорость течения времени
	time_manager.set_time_scale(scale)
}

func _on_pause_toggled(is_paused: bool) -> void {
	# Обновляем статус паузы
	time_manager.set_paused(is_paused)
}

func _on_game_over(reason: String) -> void {
	# Обработка окончания игры
	time_manager.set_paused(true)
}

# Переключение режима производства
func _on_production_mode_changed(mode: String) -> void {
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
func show_upgrade_menu(production_type: String) -> void {
	var upgrade_menu = preload("res://scenes/ui/UpgradeMenu.tscn").instantiate()
	upgrade_menu.filter_by_type(production_type)
	upgrade_menu.connect("upgrade_selected", _on_upgrade_selected)
	add_child(upgrade_menu)
	upgrade_menu.popup_centered()

# Обработчик выбора улучшения
func _on_upgrade_selected(upgrade_id: String) -> void {
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
