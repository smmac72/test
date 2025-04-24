extends Node

# Состояния игры
enum GameState {
	MENU,       # Главное меню
	PLAYING,    # Игровой процесс
	PAUSED,     # Пауза
	GAME_OVER   # Конец игры
}

# Текущее состояние
var current_state = GameState.MENU

# Конфигурация
var config = {
	"save_file": "user://samogon_save.json",
	"auto_save_interval": 300,  # в секундах
	"max_game_days": 100,       # ограничение на количество дней
	"difficulty": 1             # 0-легко, 1-нормально, 2-сложно
}

# Таймеры
var auto_save_timer: Timer
var event_check_timer: Timer

# Сигналы
signal game_state_changed(new_state)
signal game_saved(success)
signal game_loaded(success)
signal game_reset

func _ready():
	# Инициализация таймеров
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = config["auto_save_interval"]
	auto_save_timer.one_shot = false
	auto_save_timer.timeout.connect(_auto_save)
	add_child(auto_save_timer)
	
	# Подключаем сигналы
	GlobalState.game_over.connect(_on_game_over)
	GlobalState.game_paused.connect(_on_game_paused)
	
	# Инициализируем начальное состояние
	set_game_state(GameState.MENU)

func _input(event):
	# Обработка глобальных клавиш
	if event.is_action_pressed("ui_cancel"):
		match current_state:
			GameState.PLAYING:
				set_game_state(GameState.PAUSED)
			GameState.PAUSED:
				set_game_state(GameState.PLAYING)

func set_game_state(new_state):
	# Обработка выхода из предыдущего состояния
	match current_state:
		GameState.PLAYING:
			# Сохраняем при выходе из игрового режима
			if new_state != GameState.PAUSED:
				save_game()
			
			# Останавливаем таймеры
			auto_save_timer.stop()
		
		GameState.PAUSED:
			# Возобновляем игровой процесс
			TimeManager.resume()
	
	# Обработка входа в новое состояние
	match new_state:
		GameState.MENU:
			# Показываем главное меню
			_show_main_menu()
		
		GameState.PLAYING:
			# Запускаем игровой процесс
			TimeManager.resume()
			auto_save_timer.start()
		
		GameState.PAUSED:
			# Приостанавливаем игровой процесс
			TimeManager.pause()
		
		GameState.GAME_OVER:
			# Показываем экран окончания игры
			_show_game_over_screen()
	
	# Обновляем состояние
	current_state = new_state
	game_state_changed.emit(new_state)

func start_new_game(difficulty: int = 1):
	# Сбрасываем состояние игры
	reset_game_state()
	
	# Устанавливаем сложность
	config["difficulty"] = difficulty
	_apply_difficulty_settings(difficulty)
	
	# Переходим в игровой режим
	set_game_state(GameState.PLAYING)

func continue_game():
	# Загружаем сохранение и продолжаем игру
	if load_game():
		set_game_state(GameState.PLAYING)

func reset_game_state():
	# Сбрасываем все игровые данные к начальным значениям
	GlobalState.money = 1500
	GlobalState.reputation = 100
	GlobalState.current_day = 0
	GlobalState.has_debt = false
	GlobalState.debt_amount = 0
	GlobalState.debt_due_day = 0
	GlobalState.stats = {
		"products_made": {},
		"sales": {},
		"total_income": 0,
		"total_expenses": 0,
		"fines_paid": 0,
		"customers_served": 0,
		"failed_orders": 0
	}
	
	# Сбрасываем менеджеры
	DataService._initialize_base_content()
	
	# Сбрасываем улучшения
	UpgradeManager.current_levels = {
		"samogon": 1,
		"beer": 0,
		"wine": 0,
		"garage": 1
	}
	UpgradeManager.tool_levels = {}
	UpgradeManager._initialize_tools()
	
	# Сбрасываем время
	TimeManager.game_minutes = 8 * 60  # 8:00
	TimeManager._update_time_components()
	
	# Уведомляем о сбросе игры
	game_reset.emit()

func save_game():
	# Создаем объект с данными игры
	var save_data = {
		"version": "1.0",
		"date": Time.get_datetime_string_from_system(),
		"config": config,
		"global_state": GlobalState.save_data(),
		"data_service": DataService.save_data(),
		"upgrade_manager": UpgradeManager.save_data(),
		"time_manager": {
			"game_minutes": TimeManager.game_minutes
		}
	}
	
	# Сохраняем в файл
	var success = _save_to_file(save_data)
	game_saved.emit(success)
	return success

func load_game():
	# Загружаем данные из файла
	var save_data = _load_from_file()
	if save_data.is_empty():
		game_loaded.emit(false)
		return false
	
	# Проверяем версию сохранения
	if save_data.get("version", "") != "1.0":
		print("Warning: Loading save from different version")
	
	# Загружаем настройки
	if save_data.has("config"):
		config = save_data["config"]
	
	# Загружаем состояние игры
	if save_data.has("global_state"):
		GlobalState.load_data(save_data["global_state"])
	
	# Загружаем данные сервиса
	if save_data.has("data_service"):
		DataService.load_data(save_data["data_service"])
	
	# Загружаем улучшения
	if save_data.has("upgrade_manager"):
		UpgradeManager.load_data(save_data["upgrade_manager"])
	
	# Загружаем время
	if save_data.has("time_manager"):
		TimeManager.game_minutes = save_data["time_manager"].get("game_minutes", 8 * 60)
		TimeManager._update_time_components()
	
	# Уведомляем о загрузке
	game_loaded.emit(true)
	return true

func _save_to_file(data):
	# Сохраняем в файл
	var file = FileAccess.open(config["save_file"], FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.flush()
		return true
	return false

func _load_from_file():
	# Проверяем существование файла
	if not FileAccess.file_exists(config["save_file"]):
		return {}
	
	# Загружаем файл
	var file = FileAccess.open(config["save_file"], FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var data = JSON.parse_string(json_string)
		if data is Dictionary:
			return data
	
	return {}

func _auto_save():
	# Автосохранение
	save_game()

func _show_main_menu():
	# Показываем главное меню
	# Это будет реализовано в UI-сцене
	pass

func _show_game_over_screen():
	# Показываем экран окончания игры
	# Это будет реализовано в UI-сцене
	pass

func _on_game_over(reason):
	# Обработка окончания игры
	print("Game over: " + reason)
	set_game_state(GameState.GAME_OVER)

func _on_game_paused(is_paused):
	# Обработка паузы
	if is_paused:
		set_game_state(GameState.PAUSED)
	else:
		set_game_state(GameState.PLAYING)

func _apply_difficulty_settings(difficulty):
	# Применяем настройки сложности
	match difficulty:
		0:  # Легко
			GlobalState.money = 2000
			GlobalState.reputation = 120
		1:  # Нормально
			GlobalState.money = 1500
			GlobalState.reputation = 100
		2:  # Сложно
			GlobalState.money = 1000
			GlobalState.reputation = 80
