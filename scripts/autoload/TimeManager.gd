class_name TimeManager
extends Node

# Сигналы
signal minute_passed(game_time)
signal hour_passed(game_time)
signal day_passed(game_date)
signal time_of_day_changed(new_time)
signal time_scale_changed(new_scale)

# Игровое время и дата
var game_time: Dictionary = {
	"hour": 8,
	"minute": 0
}

var game_date: Dictionary = {
	"day": 1,
	"month": 1,
	"year": 2023
}

# Время суток
enum TimeOfDay { MORNING, DAY, EVENING, NIGHT }
var current_time_of_day: TimeOfDay = TimeOfDay.MORNING
var time_of_day_name: String = "morning"

# Настройки времени
var time_scale: float = 1.0  # 1 секунда реального времени = time_scale минут игрового времени
var paused: bool = false

# Таймер обновления времени
var time_timer: Timer

# Ссылки на другие системы
@onready var game_manager: GameManager = $"/root/GM"
@onready var event_manager: EventManager = $"/root/EM"
@onready var audio_manager: AudioManager = $"/root/AM"
@onready var save_manager: SaveManager = $"/root/SM"

# Инициализация
func _ready() -> void:
	if save_manager:
		save_manager.register_system("time", self)
	# Создаем таймер
	time_timer = Timer.new()
	add_child(time_timer)
	time_timer.wait_time = 1.0  # 1 секунда
	time_timer.connect("timeout", _on_timer_timeout)
	time_timer.autostart = true
	
	# Инициализируем время суток
	_update_time_of_day()

# Обработчик таймера
func _on_timer_timeout() -> void:
	if paused:
		return
	
	# Продвигаем время на time_scale минут
	advance_time(time_scale)

# Продвижение времени на указанное количество минут
func advance_time(minutes: float) -> void:
	# Обрабатываем целые минуты
	var whole_minutes = int(minutes)
	
	# Запоминаем старый час и день для проверки перехода
	var old_hour = game_time["hour"]
	var old_day = game_date["day"]
	var old_time_of_day = current_time_of_day
	
	# Добавляем минуты
	game_time["minute"] += whole_minutes
	
	# Обрабатываем переполнение минут
	while game_time["minute"] >= 60:
		game_time["minute"] -= 60
		game_time["hour"] += 1
		
		# Проверяем переход на новый день
		if game_time["hour"] >= 24:
			game_time["hour"] = 0
			game_date["day"] += 1
			
			# Проверяем переход на новый месяц
			var days_in_month = _get_days_in_month(game_date["month"], game_date["year"])
			if game_date["day"] > days_in_month:
				game_date["day"] = 1
				game_date["month"] += 1
				
				# Проверяем переход на новый год
				if game_date["month"] > 12:
					game_date["month"] = 1
					game_date["year"] += 1
	
	# Обновляем время суток
	_update_time_of_day()
	
	# Отправляем сигнал о прошедшей минуте
	emit_signal("minute_passed", game_time)
	
	# Проверяем, прошел ли час
	if game_time["hour"] != old_hour:
		emit_signal("hour_passed", game_time)
		
		# Проверяем, изменилось ли время суток
		if current_time_of_day != old_time_of_day:
			emit_signal("time_of_day_changed", time_of_day_name)
			
			# Воспроизведение звука времени суток
			if audio_manager:
				audio_manager.play_ambient_for_time_of_day(time_of_day_name)
	
	# Проверяем, прошел ли день
	if game_date["day"] != old_day:
		emit_signal("day_passed", game_date)
		
		# Уведомляем игровой менеджер о новом дне
		game_manager.handle_new_day(game_date["day"])
		
		# Генерируем события на новый день
		event_manager.generate_daily_events()

# Обновление времени суток
func _update_time_of_day() -> void:
	var hour = game_time["hour"]
	
	var new_time_of_day = TimeOfDay.DAY
	var new_time_name = "day"
	
	if hour >= 6 and hour < 12:
		new_time_of_day = TimeOfDay.MORNING
		new_time_name = "morning"
	elif hour >= 12 and hour < 18:
		new_time_of_day = TimeOfDay.DAY
		new_time_name = "day"
	elif hour >= 18 and hour < 24:
		new_time_of_day = TimeOfDay.EVENING
		new_time_name = "evening"
	else:  # 0-5
		new_time_of_day = TimeOfDay.NIGHT
		new_time_name = "night"
	
	# Применяем новое время суток, если оно изменилось
	if new_time_of_day != current_time_of_day:
		current_time_of_day = new_time_of_day
		time_of_day_name = new_time_name

# Получение количества дней в месяце
func _get_days_in_month(month: int, year: int) -> int:
	match month:
		2:  # Февраль
			# Проверка на високосный год
			if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
				return 29
			else:
				return 28
		4, 6, 9, 11:  # Апрель, Июнь, Сентябрь, Ноябрь
			return 30
		_:  # Остальные месяцы
			return 31

# Установка масштаба времени
func set_time_scale(new_scale: float) -> void:
	time_scale = new_scale
	emit_signal("time_scale_changed", time_scale)

# Пауза/возобновление времени
func set_paused(is_paused: bool) -> void:
	paused = is_paused

# Получение текущего времени в виде строки
func get_time_string() -> String:
	var hour_str = str(game_time["hour"]).pad_zeros(2)
	var minute_str = str(game_time["minute"]).pad_zeros(2)
	return hour_str + ":" + minute_str

# Получение текущей даты в виде строки
func get_date_string() -> String:
	var day_str = str(game_date["day"]).pad_zeros(2)
	var month_str = str(game_date["month"]).pad_zeros(2)
	var year_str = str(game_date["year"])
	return day_str + "." + month_str + "." + year_str

# Получение текущего дня недели
func get_weekday() -> String:
	# Определяем день недели (1 = Понедельник, ..., 7 = Воскресенье)
	var days_since_epoch = _days_since_epoch(game_date["year"], game_date["month"], game_date["day"])
	var weekday = (days_since_epoch + 1) % 7  # 01.01.2023 был воскресеньем (7)
	if weekday == 0:
		weekday = 7
	
	match weekday:
		1: return "Понедельник"
		2: return "Вторник"
		3: return "Среда"
		4: return "Четверг"
		5: return "Пятница"
		6: return "Суббота"
		7: return "Воскресенье"
	
	return "Неизвестно"

# Вспомогательная функция для расчета дня недели
func _days_since_epoch(year: int, month: int, day: int) -> int:
	# Простое приближение для игровых целей (не учитывает смены календарей и т.д.)
	var days = 0
	
	# Дни за предыдущие годы (считая от 2023)
	for y in range(2023, year):
		days += 365
		if (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0):
			days += 1
	
	# Дни за предыдущие месяцы текущего года
	for m in range(1, month):
		days += _get_days_in_month(m, year)
	
	# Дни текущего месяца
	days += day - 1
	
	return days

# Получение сезона
func get_season() -> String:
	match game_date["month"]:
		12, 1, 2:
			return "winter"
		3, 4, 5:
			return "spring"
		6, 7, 8:
			return "summer"
		9, 10, 11:
			return "fall"
	
	return "unknown"

# Получение данных времени для сохранения
func get_time_data() -> Dictionary:
	return {
		"game_time": game_time,
		"game_date": game_date,
		"time_of_day": time_of_day_name,
		"time_scale": time_scale,
		"paused": paused
	}

# Загрузка данных времени из сохранения
func load_time_data(data: Dictionary) -> void:
	if "game_time" in data:
		game_time = data["game_time"]
	
	if "game_date" in data:
		game_date = data["game_date"]
	
	if "time_of_day" in data:
		time_of_day_name = data["time_of_day"]
		# Обновляем enum на основе имени
		match time_of_day_name:
			"morning": current_time_of_day = TimeOfDay.MORNING
			"day": current_time_of_day = TimeOfDay.DAY
			"evening": current_time_of_day = TimeOfDay.EVENING
			"night": current_time_of_day = TimeOfDay.NIGHT
	
	if "time_scale" in data:
		time_scale = data["time_scale"]
	
	if "paused" in data:
		paused = data["paused"]

# Интерфейс для SaveManager - получение данных для сохранения
func get_save_data() -> Dictionary:
	return get_time_data()

# Интерфейс для SaveManager - загрузка данных из сохранения
func load_save_data(data: Dictionary) -> void:
	if "game_time" in data:
		game_time = data["game_time"]
	
	if "game_date" in data:
		game_date = data["game_date"]
	
	if "time_of_day" in data:
		time_of_day_name = data["time_of_day"]
		# Обновляем enum на основе имени
		match time_of_day_name:
			"morning": current_time_of_day = TimeOfDay.MORNING
			"day": current_time_of_day = TimeOfDay.DAY
			"evening": current_time_of_day = TimeOfDay.EVENING
			"night": current_time_of_day = TimeOfDay.NIGHT
			
	if "time_scale" in data:
		time_scale = data["time_scale"]
	
	if "paused" in data:
		paused = data["paused"]

	print("TimeManager: Загрузка сохранения завершена")
