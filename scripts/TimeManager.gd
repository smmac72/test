extends Node

# Настройки времени
@export var seconds_per_game_minute: float = 1.0  # Реальное время на 1 игровую минуту
@export var start_hour: int = 8  # Начало дня
@export var end_hour: int = 22   # Конец дня

# Внутренние переменные
var game_minutes: int = 0  # Общее количество игровых минут с начала игры
var current_hour: int = 0  # Текущий час (0-23)
var current_minute: int = 0  # Текущая минута (0-59)
var current_day: int = 0  # Текущий игровой день

var _accum: float = 0.0  # Аккумулятор для отсчета времени
var _paused: bool = false  # Приостановлено ли время

# Сигналы
signal minute_passed(game_minutes)
signal hour_changed(hour)
signal day_changed(day)
signal day_night_changed(is_night)

func _ready() -> void:
	# Инициализация начального времени
	game_minutes = start_hour * 60
	_update_time_components()

func _process(delta: float) -> void:
	if _paused:
		return
	
	_accum += delta
	
	if _accum >= seconds_per_game_minute:
		_accum -= seconds_per_game_minute
		_advance_time()

func _advance_time() -> void:
	game_minutes += 1
	
	var prev_hour = current_hour
	var prev_day = current_day
	
	_update_time_components()
	
	# Проверяем смену часа
	if current_hour != prev_hour:
		emit_signal("hour_changed", current_hour)
		
		# Проверяем конец дня
		if current_hour == 0:
			current_day += 1
			GlobalState.next_day()
			emit_signal("day_changed", current_day)
		
		# Проверяем смену дня/ночи
		var is_night = current_hour < 6 or current_hour >= 20
		if (prev_hour < 6 or prev_hour >= 20) != is_night:
			emit_signal("day_night_changed", is_night)
	
	# Уведомляем о прошедшей минуте
	emit_signal("minute_passed", game_minutes)

func _update_time_components() -> void:
	current_hour = (game_minutes / 60) % 24
	current_minute = game_minutes % 60
	current_day = game_minutes / (24 * 60)

func get_time_string() -> String:
	# Возвращает время в формате ЧЧ:ММ
	return "%02d:%02d" % [current_hour, current_minute]

func get_day_string() -> String:
	# Возвращает день в формате "ДЕНЬ X"
	return "ДЕНЬ %d" % current_day

func pause() -> void:
	_paused = true

func resume() -> void:
	_paused = false

func set_time_scale(scale: float) -> void:
	# Устанавливает скорость течения времени
	seconds_per_game_minute = 1.0 / max(0.1, scale)

func jump_to_next_day() -> void:
	# Перемотка до начала следующего дня
	var minutes_till_midnight = (24 * 60) - (game_minutes % (24 * 60))
	game_minutes += minutes_till_midnight
	_update_time_components()
	
	# Уведомляем об изменениях
	emit_signal("hour_changed", current_hour)
	emit_signal("day_changed", current_day)
	emit_signal("day_night_changed", true)  # В полночь всегда ночь
	emit_signal("minute_passed", game_minutes)

func jump_to_time(hour: int, minute: int = 0) -> void:
	# Сохраняем текущий день
	var day_start = (game_minutes / (24 * 60)) * 24 * 60
	
	# Вычисляем новое время
	var new_minutes = day_start + (hour * 60) + minute
	
	# Если указанное время уже прошло сегодня, переходим на следующий день
	if new_minutes < game_minutes:
		new_minutes += 24 * 60
	
	# Устанавливаем новое время
	game_minutes = new_minutes
	_update_time_components()
	
	# Уведомляем об изменениях
	emit_signal("hour_changed", current_hour)
	emit_signal("minute_passed", game_minutes)
	
	var is_night = current_hour < 6 or current_hour >= 20
	emit_signal("day_night_changed", is_night)

func is_business_hours() -> bool:
	# Проверяет, находится ли текущее время в рабочие часы
	return current_hour >= start_hour and current_hour < end_hour

func get_minutes_until(target_hour: int, target_minute: int = 0) -> int:
	# Вычисляем целевое время в минутах
	var target_minutes = target_hour * 60 + target_minute
	var current_minutes = current_hour * 60 + current_minute
	
	# Если целевое время раньше текущего, добавляем день
	if target_minutes <= current_minutes:
		target_minutes += 24 * 60
	
	return target_minutes - current_minutes
