extends Control

# Ссылки на сцены
@onready var top_hud = $AspectRatioContainer/VBoxContainer/TopHUD
@onready var shop_panel = $AspectRatioContainer/VBoxContainer/HBoxContainer/ShopPanel
@onready var production_panel = $AspectRatioContainer/VBoxContainer/HBoxContainer/ProductionPanel
@onready var recipe_book = $RecipeBook
@onready var upgrade_window = $UpgradeWindow
@onready var pause_menu = $PauseMenu
@onready var game_over_screen = $GameOverScreen
@onready var statistics_screen = $StatisticsScreen

# Биндинги кнопок верхнего меню
@onready var btn_recipes = $AspectRatioContainer/VBoxContainer/TopHUD/HBox/Menu/BtnRecipes
@onready var btn_upgrades = $AspectRatioContainer/VBoxContainer/TopHUD/HBox/Menu/BtnUpgrades
@onready var btn_stats = $AspectRatioContainer/VBoxContainer/TopHUD/HBox/Menu/BtnStats

# Биндинги кнопок меню паузы
@onready var btn_resume = $PauseMenu/VBox/BtnResume
@onready var btn_save = $PauseMenu/VBox/BtnSave
@onready var btn_load = $PauseMenu/VBox/BtnLoad
@onready var btn_settings = $PauseMenu/VBox/BtnSettings
@onready var btn_quit = $PauseMenu/VBox/BtnQuit

# Биндинги UI статистики
@onready var game_over_stats = $GameOverScreen/VBox/StatsContainer
@onready var statistics_container = $StatisticsScreen/VBox/Scroll/StatsContainer
@onready var statistics_close = $StatisticsScreen/BtnClose

# Биндинги экрана завершения игры
@onready var game_over_reason = $GameOverScreen/VBox/LabelReason
@onready var btn_restart = $GameOverScreen/VBox/BtnRestart
@onready var btn_quit_to_menu = $GameOverScreen/VBox/BtnQuit

@onready var back_cound = $BackgroundBirds
# Перетаскивание между панелями
var is_dragging = false
var dragged_item = null

var time: float = 0.0
var amplitude: float = 30.0  # Амплитуда движения (в пикселях)
var frequency: float = 1.0   # Частота колебаний
var base_positions: Array = []

func _ready():
	back_cound.play()
	# Подключаем сигналы верхнего меню
	btn_recipes.pressed.connect(_on_recipes_pressed)
	btn_upgrades.pressed.connect(_on_upgrades_pressed)
	btn_stats.pressed.connect(_on_stats_pressed)
	
	# Подключаем сигналы меню паузы
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	
	# Подключаем сигналы статистики
	statistics_close.pressed.connect(_on_statistics_close)
	
	# Подключаем сигналы экрана завершения игры
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_quit_to_menu.pressed.connect(_on_quit_pressed)
	
	# Подключаем сигналы менеджеров
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GlobalState.game_over.connect(_on_game_over)
	GlobalState.money_changed.connect(_update_money_display)
	GlobalState.reputation_changed.connect(_update_reputation_display)
	GlobalState.day_passed.connect(_update_day_display)
	
	TimeManager.minute_passed.connect(_on_time_update)
	
	# Подключаем события для перетаскивания между панелями
	production_panel.product_created.connect(_on_product_created)
	
	# Начальное обновление UI
	_update_money_display(GlobalState.money)
	_update_reputation_display(GlobalState.reputation)
	_update_day_display(GlobalState.current_day)
	_on_time_update(TimeManager.game_minutes)

func _input(event):
	# Глобальные клавиши
	if event.is_action_pressed("ui_cancel"):
		if recipe_book.visible:
			recipe_book.visible = false
		elif upgrade_window.visible:
			upgrade_window.visible = false
		elif statistics_screen.visible:
			statistics_screen.visible = false
		else:
			_toggle_pause()

func _on_recipes_pressed():
	# Показываем/скрываем книгу рецептов
	recipe_book.visible = !recipe_book.visible
	recipe_book.move_to_front()
	# Скрываем другие окна
	upgrade_window.visible = false
	statistics_screen.visible = false

func _on_upgrades_pressed():
	# Показываем/скрываем окно улучшений
	upgrade_window.visible = !upgrade_window.visible
	
	# Обновляем содержимое окна улучшений
	if upgrade_window.visible:
		upgrade_window.move_to_front()
		upgrade_window.open()
	
	# Скрываем другие окна
	recipe_book.visible = false
	statistics_screen.visible = false

func _on_stats_pressed():
	# Показываем/скрываем окно статистики
	statistics_screen.visible = !statistics_screen.visible
	
	# Обновляем содержимое окна статистики
	if statistics_screen.visible:
		statistics_screen.move_to_front()
		_update_statistics_screen()
	
	# Скрываем другие окна
	recipe_book.visible = false
	upgrade_window.visible = false

func _on_resume_pressed():
	# Возобновляем игру
	GlobalState.set_pause(false)

func _on_save_pressed():
	# Сохраняем игру
	GameManager.save_game()
	
	# Показываем сообщение
	PopupManager.show_message("Игра сохранена", 2.0, Color(0, 1, 0))


func _on_load_pressed():
	# Загружаем игру
	if GameManager.load_game():
		GlobalState.set_pause(false)
		PopupManager.show_message("Игра загружена", 2.0, Color(0, 1, 0))
	else:
		PopupManager.show_message("Ошибка загрузки", 2.0, Color(1, 0, 0))

func _on_settings_pressed():
	# Показываем окно настроек (пока не реализовано)
	PopupManager.show_message("Настройки (не реализовано)", 2.0)

func _on_quit_pressed():
	# Выходим в главное меню
	GameManager.save_game()  # Автосохранение
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_restart_pressed():
	# Начинаем новую игру
	GameManager.start_new_game(GameManager.config["difficulty"])
	
	# Скрываем экран окончания игры
	game_over_screen.visible = false

func _on_statistics_close():
	# Скрываем окно статистики
	statistics_screen.visible = false

func _on_game_state_changed(new_state):
	# Обрабатываем изменение состояния игры
	match new_state:
		GameManager.GameState.PLAYING:
			pause_menu.visible = false
			game_over_screen.visible = false
		
		GameManager.GameState.PAUSED:
			pause_menu.visible = true
			pause_menu.move_to_front()
		
		GameManager.GameState.GAME_OVER:
			game_over_screen.visible = true
			game_over_screen.move_to_front()
			_update_game_over_screen()

func _on_game_over(reason):
	# Обрабатываем окончание игры
	match reason:
		"bankruptcy":
			game_over_reason.text = "Вы обанкротились!"
		"debt":
			game_over_reason.text = "Вы не смогли выплатить кредит!"
		"bad_reputation":
			game_over_reason.text = "Ваша репутация разрушена!"
		_:
			game_over_reason.text = "Игра окончена"
	
	_update_game_over_screen()

func _toggle_pause():
	# Переключаем состояние паузы
	GlobalState.toggle_pause()

func _update_money_display(value):
	# Обновляем отображение денег
	top_hud.get_node("HBox/LblMoney").text = "₽ " + str(value)

func _update_reputation_display(value):
	# Обновляем отображение репутации
	top_hud.get_node("HBox/LblRep").text = "REP: " + str(value)

func _update_day_display(day):
	# Обновляем отображение дня
	top_hud.get_node("HBox/LblDay").text = "ДЕНЬ " + str(day)

func _on_time_update(game_minutes):
	# Обновляем отображение времени
	var hours = int(game_minutes / 60) % 24
	var minutes = game_minutes % 60
	top_hud.get_node("HBox/LblTime").text = "%02d:%02d" % [hours, minutes]

func _update_statistics_screen():
	# Очищаем контейнер
	for child in statistics_container.get_children():
		child.queue_free()
	
	# Добавляем основную статистику
	_add_stat_label("Общий доход: " + str(GlobalState.stats["total_income"]) + "₽")
	_add_stat_label("Общие расходы: " + str(GlobalState.stats["total_expenses"]) + "₽")
	_add_stat_label("Прибыль: " + str(GlobalState.stats["total_income"] - GlobalState.stats["total_expenses"]) + "₽")
	_add_stat_label("Штрафы: " + str(GlobalState.stats["fines_paid"]) + "₽")
	_add_stat_label("Обслужено клиентов: " + str(GlobalState.stats["customers_served"]))
	_add_stat_label("Проваленных заказов: " + str(GlobalState.stats["failed_orders"]))
	
	# Добавляем разделитель
	var separator = HSeparator.new()
	statistics_container.add_child(separator)
	
	# Добавляем статистику по продуктам
	var products_label = Label.new()
	products_label.text = "Произведено:"
	products_label.add_theme_font_size_override("font_size", 16)
	statistics_container.add_child(products_label)
	
	# Перебираем произведенные продукты
	for product_id in GlobalState.stats.get("products_made", {}):
		var count = GlobalState.stats["products_made"][product_id]
		var product_info = DataService.find_item(product_id)
		var name = product_info.get("name", product_id)
		
		_add_stat_label("- " + name + ": " + str(count))
	
	# Добавляем разделитель
	separator = HSeparator.new()
	statistics_container.add_child(separator)
	
	# Добавляем статистику по продажам
	var sales_label = Label.new()
	sales_label.text = "Продано:"
	sales_label.add_theme_font_size_override("font_size", 16)
	statistics_container.add_child(sales_label)
	
	# Перебираем проданные продукты
	for product_id in GlobalState.stats.get("sales", {}):
		var count = GlobalState.stats["sales"][product_id]
		var product_info = DataService.find_item(product_id)
		var name = product_info.get("name", product_id)
		
		_add_stat_label("- " + name + ": " + str(count))

func _update_game_over_screen():
	# Очищаем контейнер
	for child in game_over_stats.get_children():
		child.queue_free()
	
	# Добавляем основную статистику
	_add_stat_label("Дни в игре: " + str(GlobalState.current_day), game_over_stats)
	_add_stat_label("Общий доход: " + str(GlobalState.stats["total_income"]) + "₽", game_over_stats)
	_add_stat_label("Обслужено клиентов: " + str(GlobalState.stats["customers_served"]), game_over_stats)
	_add_stat_label("Произведено продуктов: " + str(_count_total_products()), game_over_stats)

func _add_stat_label(text, container = null):
	# Вспомогательная функция для добавления метки статистики
	if container == null:
		container = statistics_container
	
	var label = Label.new()
	label.text = text
	container.add_child(label)

func _count_total_products():
	# Подсчет общего количества произведенных продуктов
	var total = 0
	for count in GlobalState.stats.get("products_made", {}).values():
		total += count
	return total

func _on_product_created(product_data):
	# Обрабатываем создание нового продукта
	var product_id = product_data.get("id", "")
	
	# Обновляем статистику
	if product_id != "":
		if not GlobalState.stats["products_made"].has(product_id):
			GlobalState.stats["products_made"][product_id] = 0
		
		GlobalState.stats["products_made"][product_id] += 1
	
	# Обучаем рецепт
	RecipeManager.learn_recipe(product_id)
