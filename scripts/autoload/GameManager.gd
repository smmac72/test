class_name GameManager
extends Node

# Сигналы
signal money_changed(new_amount, change, reason)
signal reputation_changed(new_reputation, change, reason)
signal day_changed(new_day)
signal production_level_changed(production_type, new_level)
signal loan_taken(amount, due_date)
signal loan_repaid()
signal game_over(reason)
signal game_initialized

# Данные игрока
var money: int = 500
var game_day: int = 1
var is_new_game: bool = true

# Уровни производства
var production_levels: Dictionary = {
	"samogon": 1,  # Уровень 1 доступен сразу
	"beer": 0,     # Уровень 0 означает, что не разблокировано
	"wine": 0,
	"garage": 1    # Уровень склада/рабочей зоны
}

# Данные по займу
var loan_amount: int = 0
var loan_due_day: int = 0

# Ежедневные расходы
var utility_cost: int = 100  # Стоимость коммунальных платежей

# Флаг окончания игры
var is_game_over: bool = false
var is_initialized: bool = false

# Сохраняемые настройки
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"ui_volume": 0.5,
	"ambient_volume": 0.6,
	"tutorial_completed": false
}

# Ссылки на другие системы
@onready var config_manager: ConfigManager = $"/root/ConfigManager"
@onready var time_manager: TimeManager = $"/root/TimeManager"
@onready var production_manager: ProductionManager = $"/root/ProductionManager"
@onready var customer_manager: CustomerManager = $"/root/CustomerManager"
@onready var event_manager: EventManager = $"/root/EventManager"
@onready var audio_manager: AudioManager = $"/root/AudioManager"
@onready var save_manager: SaveManager = $"/root/SaveManager"

# Инициализация
func _ready() -> void:
	# Регистрируем систему в SaveManager
	if save_manager:
		save_manager.register_system("game", self)
		save_manager.connect("load_completed", _on_save_load_completed)
	
	# Загружаем настройки
	load_settings()
	
	# Применяем настройки звука
	apply_audio_settings()
	
	# Проверяем наличие сохранения
	if save_manager and save_manager.has_save():
		is_new_game = false
	
	call_deferred("initialize_game_state")

# Инициализация игрового состояния (после загрузки других менеджеров)
func initialize_game_state() -> void:
	# Дожидаемся загрузки конфигураций
	if not config_manager.is_loaded:
		await config_manager.configs_loaded
	
	# Проверяем, новая ли игра
	if is_new_game:
		# Новая игра - сбрасываем все на начальные значения
		reset_game()
	else:
		# Продолжаем игру - загружаем сохранение
		if save_manager:
			save_manager.load_game()
		else:
			# Запасной вариант если SaveManager не доступен
			reset_game()
	
	is_initialized = true
	emit_signal("game_initialized")

# Обработчик завершения загрузки сохранения
func _on_save_load_completed() -> void:
	# Обновляем UI
	emit_signal("money_changed", money, 0, "Загрузка")
	emit_signal("day_changed", game_day)
	
	for type in production_levels:
		emit_signal("production_level_changed", type, production_levels[type])

# Сброс игры на начальные значения
func reset_game() -> void:
	money = 500
	game_day = 1
	production_levels = {
		"samogon": 1,
		"beer": 0,
		"wine": 0,
		"garage": 1
	}
	loan_amount = 0
	loan_due_day = 0
	is_game_over = false
	is_new_game = false
	
	# Сохраняем начальное состояние
	if save_manager:
		save_manager.save_game()

# Интерфейс для SaveManager - получение данных для сохранения
func get_save_data() -> Dictionary:
	return {
		"money": money,
		"game_day": game_day,
		"production_levels": production_levels,
		"loan_amount": loan_amount,
		"loan_due_day": loan_due_day,
		"is_game_over": is_game_over
	}

# Интерфейс для SaveManager - загрузка данных из сохранения
func load_save_data(data: Dictionary) -> void:
	# Загружаем основные данные
	money = data.get("money", 500)
	game_day = data.get("game_day", 1)
	
	# Загружаем уровни производства
	if "production_levels" in data:
		production_levels = data.get("production_levels", {
			"samogon": 1,
			"beer": 0,
			"wine": 0,
			"garage": 1
		})
	
	# Загружаем данные займа
	loan_amount = data.get("loan_amount", 0)
	loan_due_day = data.get("loan_due_day", 0)
	is_game_over = data.get("is_game_over", false)
	
	print("GameManager: Загрузка сохранения завершена")

# Изменение количества денег
func change_money(amount: int, reason: String = "") -> void:
	var old_money = money
	money += amount
	
	# Проверка на банкротство, если деньги закончились
	if old_money >= 0 and money < 0 and loan_amount == 0:
		# Предлагаем взять займ
		var needed_amount = abs(money) + 100  # Немного больше, чем нужно
		offer_loan(needed_amount, "Срочный займ для покрытия расходов")
	
	# Отправляем сигнал об изменении
	emit_signal("money_changed", money, amount, reason)
	
	# Воспроизводим звук в зависимости от типа изменения
	if audio_manager:
		if amount > 0:
			audio_manager.play_sound("money_gain", AudioManager.SoundType.UI)
		elif amount < 0:
			audio_manager.play_sound("money_loss", AudioManager.SoundType.UI)
	
	# Автоматически сохраняем игру при изменении денег
	if save_manager:
		save_manager.save_game()

# Обработка нового дня
func handle_new_day(day: int) -> void:
	game_day = day
	
	# Отправляем сигнал о смене дня
	emit_signal("day_changed", game_day)
	
	# Обрабатываем ежедневные платежи и проверки
	check_loan_status()
	
	# Сохраняем прогресс
	if save_manager:
		save_manager.save_game()

# Проверка состояния займа
func check_loan_status() -> void:
	if loan_amount > 0 and game_day >= loan_due_day:
		# Пора выплачивать займ
		if money >= loan_amount:
			# Есть деньги - выплачиваем займ
			change_money(-loan_amount, "Выплата займа")
			loan_amount = 0
			loan_due_day = 0
			emit_signal("loan_repaid")
		else:
			# Нет денег - предлагаем новый займ
			offer_loan(loan_amount * 1.5, "Рефинансирование займа")

# Предложение займа
func offer_loan(amount: int, reason: String) -> void:
	# Создаем диалог предложения займа
	var loan_dialog = preload("res://scenes/ui/LoanDialog.tscn").instantiate()
	loan_dialog.setup(amount, reason)
	loan_dialog.connect("loan_accepted", _on_loan_accepted)
	loan_dialog.connect("loan_rejected", _on_loan_rejected)
	
	# Добавляем диалог на сцену
	var ui_layer = get_tree().get_nodes_in_group("ui_layer")
	if ui_layer.size() > 0:
		ui_layer[0].add_child(loan_dialog)
	else:
		get_tree().current_scene.add_child(loan_dialog)
	
	loan_dialog.popup_centered()

# Взятие займа
func take_loan(amount: int) -> void:
	loan_amount = amount
	loan_due_day = game_day + 7  # Займ на 7 дней
	
	# Добавляем деньги от займа
	change_money(amount, "Получение займа")
	
	# Отправляем сигнал о взятии займа
	emit_signal("loan_taken", amount, loan_due_day)

# Обработчики диалога займа
func _on_loan_accepted(amount: int) -> void:
	take_loan(amount)

func _on_loan_rejected() -> void:
	# Если деньги отрицательные, а займ отклонен - это конец игры
	if money < 0:
		trigger_game_over("Банкротство - отрицательный баланс без возможности займа")

# Покупка улучшения производства
func purchase_upgrade(production_type: String, level: int) -> bool:
	# Получаем данные улучшения
	var upgrade_data = config_manager.get_upgrade(production_type, level)
	if upgrade_data.size() == 0:
		return false
	
	# Проверяем, хватает ли денег
	var cost = upgrade_data.get("cost", 0)
	if money < cost:
		return false
	
	# Списываем деньги
	change_money(-cost, "Покупка улучшения: " + upgrade_data.get("name", ""))
	
	# Обновляем уровень производства
	production_levels[production_type] = level
	
	# Разблокируем новый контент
	production_manager.unlock_production_level(production_type, level)
	
	# Отправляем сигнал об изменении
	emit_signal("production_level_changed", production_type, level)
	
	# Сохраняем игру
	if save_manager:
		save_manager.save_game()
	
	return true

# Конец игры
func trigger_game_over(reason: String) -> void:
	if is_game_over:
		return
	
	is_game_over = true
	
	# Отправляем сигнал о конце игры
	emit_signal("game_over", reason)
	
	# Показываем экран окончания игры
	var game_over_screen = preload("res://scenes/ui/GameOverScreen.tscn").instantiate()
	game_over_screen.setup(reason, {
		"day": game_day,
		"money": money
	})
	
	get_tree().current_scene.add_child(game_over_screen)
	game_over_screen.popup_centered()

# Начало новой игры
func start_new_game() -> void:
	# Удаляем существующее сохранение
	if save_manager:
		save_manager.delete_save()
	
	# Устанавливаем флаг новой игры
	is_new_game = true
	
	# Перезагружаем основную сцену
	get_tree().change_scene_to_file("res://scenes/global/MainScene.tscn")

# Загрузка настроек
func load_settings() -> void:
	var settings_path = "user://settings.json"
	
	# Проверяем наличие файла настроек
	if not FileAccess.file_exists(settings_path):
		# Для веб-версии проверяем localStorage
		if OS.has_feature("web") and Engine.has_singleton("JavaScript"):
			var JavaScript = Engine.get_singleton("JavaScript")
			var json_str = JavaScript.eval("""
			try {
				return localStorage.getItem('samogon_settings') || '';
			} catch (e) {
				console.error('Failed to load settings from localStorage:', e);
				return '';
			}
			""")
			
			if json_str and json_str != "":
				var json = JSON.new()
				var error = json.parse(json_str)
				if error == OK:
					var data = json.get_data()
					if typeof(data) == TYPE_DICTIONARY:
						settings = data
						return
		
		# Если настроек нет, используем дефолтные
		return
	
	# Загружаем данные из файла
	var file = FileAccess.open(settings_path, FileAccess.READ)
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_str)
	if error == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			settings = data
	else:
		push_error("Ошибка загрузки настроек: " + json.get_error_message())

# Сохранение настроек
func save_settings() -> void:
	# Сохраняем в файл
	var settings_path = "user://settings.json"
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(settings, "  "))
	file.close()
	
	# Для веб-версии также сохраняем в localStorage
	if OS.has_feature("web") and Engine.has_singleton("JavaScript"):
		var JavaScript = Engine.get_singleton("JavaScript")
		JavaScript.eval("""
		try {
			localStorage.setItem('samogon_settings', JSON.stringify(%s));
		} catch (e) {
			console.error('Failed to save settings to localStorage:', e);
		}
		""" % JSON.stringify(settings))

# Применение настроек аудио
func apply_audio_settings() -> void:
	if audio_manager:
		audio_manager.set_master_volume(settings.get("master_volume", 1.0))
		audio_manager.set_music_volume(settings.get("music_volume", 0.7))
		audio_manager.set_sfx_volume(settings.get("sfx_volume", 0.8))
		audio_manager.set_ui_volume(settings.get("ui_volume", 0.5))
		audio_manager.set_ambient_volume(settings.get("ambient_volume", 0.6))

# Изменение настройки
func change_setting(key: String, value) -> void:
	settings[key] = value
	
	# Применяем настройки звука сразу
	if key.ends_with("_volume"):
		apply_audio_settings()
	
	# Сохраняем настройки
	save_settings()
