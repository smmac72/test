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

# Сохраняемые настройки
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"ui_volume": 0.5,
	"ambient_volume": 0.6
}

# Ссылки на другие системы
@onready var config_manager: ConfigManager = $"/root/ConfigManager"
@onready var time_manager: TimeManager = $"/root/TimeManager"
@onready var production_manager: ProductionManager = $"/root/ProductionManager"
@onready var customer_manager: CustomerManager = $"/root/CustomerManager"
@onready var event_manager: EventManager = $"/root/EventManager"
@onready var audio_manager: AudioManager = $"/root/AudioManager"

# Инициализация
func _ready() -> void:
	# Загружаем сохранение, если есть
	load_save_game()
	
	# Загружаем настройки
	load_settings()
	
	# Применяем настройки звука
	apply_audio_settings()
	
	# Проверяем, новая ли игра
	if is_new_game:
		# Новая игра - сбрасываем все на начальные значения
		reset_game()
	else:
		# Продолжаем игру - загружаем данные
		initialize_from_save()

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
	save_game()

# Загрузка игры из сохранения
func load_save_game() -> void:
	var save_path = "user://samogon_save.json"
	
	# Проверяем наличие файла сохранения
	if not FileAccess.file_exists(save_path):
		# Проверяем веб-сохранение
		if OS.has_feature("web") and Engine.has_singleton("JavaScript"):
			var JavaScript = Engine.get_singleton("JavaScript")
			var json_str = JavaScript.eval("""
			try {
				return localStorage.getItem('samogon_save') || '';
			} catch (e) {
				console.error('Failed to load from localStorage:', e);
				return '';
			}
			""")
			
			if json_str and json_str != "":
				var json = JSON.new()
				var error = json.parse(json_str)
				if error == OK:
					var data = json.get_data()
					if typeof(data) == TYPE_DICTIONARY:
						load_from_dictionary(data)
						is_new_game = false
						return
		
		# Если нет сохранения, это новая игра
		is_new_game = true
		return
	
	# Загружаем данные из файла
	var file = FileAccess.open(save_path, FileAccess.READ)
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_str)
	if error == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			load_from_dictionary(data)
			is_new_game = false
	else:
		push_error("Ошибка загрузки сохранения: " + json.get_error_message())
		is_new_game = true

# Загрузка данных из словаря
func load_from_dictionary(data: Dictionary) -> void:
	# Загружаем основные данные
	money = data.get("money", 500)
	game_day = data.get("game_day", 1)
	production_levels = data.get("production_levels", {
		"samogon": 1,
		"beer": 0,
		"wine": 0,
		"garage": 1
	})
	loan_amount = data.get("loan_amount", 0)
	loan_due_day = data.get("loan_due_day", 0)
	is_game_over = data.get("is_game_over", false)
	
	# Загружаем данные инвентаря, если они есть
	var inventory_data = data.get("inventory", {})
	var recipes_data = data.get("recipes", {})
	var storage_data = data.get("storage", {})
	
	# Сохраняем данные для последующей инициализации
	save_data = {
		"inventory": inventory_data,
		"recipes": recipes_data,
		"storage": storage_data
	}

# Временное хранилище для данных сохранения
var save_data: Dictionary = {}

# Инициализация из сохранения
func initialize_from_save() -> void:
	# Инициализируем менеджеры с загруженными данными
	if "inventory" in save_data:
		production_manager.load_inventory(save_data["inventory"])
	
	if "recipes" in save_data:
		production_manager.load_recipes(save_data["recipes"])
	
	if "storage" in save_data:
		customer_manager.load_storage(save_data["storage"])
	
	# Очищаем временное хранилище
	save_data.clear()
	
	# Отправляем сигналы для обновления UI
	emit_signal("money_changed", money, 0, "Загрузка")
	emit_signal("day_changed", game_day)
	
	for type in production_levels:
		emit_signal("production_level_changed", type, production_levels[type])

# Сохранение игры
func save_game() -> void:
	# Собираем данные для сохранения
	var save_data = {
		"money": money,
		"game_day": game_day,
		"production_levels": production_levels,
		"loan_amount": loan_amount,
		"loan_due_day": loan_due_day,
		"is_game_over": is_game_over,
		"inventory": production_manager.get_inventory_data(),
		"recipes": production_manager.get_recipes_data(),
		"storage": customer_manager.get_storage_data()
	}
	
	# Сохраняем в файл
	var save_path = "user://samogon_save.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "  "))
	file.close()
	
	# Для веб-версии также сохраняем в localStorage
	if OS.has_feature("web") and Engine.has_singleton("JavaScript"):
		var JavaScript = Engine.get_singleton("JavaScript")
		JavaScript.eval("""
		try {
			localStorage.setItem('samogon_save', JSON.stringify(%s));
		} catch (e) {
			console.error('Failed to save to localStorage:', e);
		}
		""" % JSON.stringify(save_data))

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
	if amount > 0:
		audio_manager.play_sound("money_gain", AudioManager.SoundType.UI)
	elif amount < 0:
		audio_manager.play_sound("money_loss", AudioManager.SoundType.UI)

# Обработка нового дня
func handle_new_day(day: int) -> void:
	game_day = day
	
	# Отправляем сигнал о смене дня
	emit_signal("day_changed", game_day)
	
	# Обрабатываем ежедневные платежи и проверки
	check_loan_status()
	
	# Сохраняем прогресс
	save_game()

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
	
	# Отправляем сигнал об изменении
	emit_signal("production_level_changed", production_type, level)
	
	# Сохраняем игру
	save_game()
	
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
	# Сбрасываем игру
	reset_game()
	
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
