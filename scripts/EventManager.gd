extends Node

signal event_triggered(event_name, payload)

var daily_events = ["utilities_payment", "client_rush"]
var random_events = ["police_razzia", "mafia_visit", "power_outage"]

@onready var popup = PopupManager

func trigger_daily():
	for e in daily_events:
		_run_event(e)
	# chance random
	if randf() < 0.05:
		_run_event(random_events[randi() % random_events.size()])

func _run_event(ev: String) -> void:
	match ev:
		"utilities_payment":
			var cost := 100 * GlobalState.current_day
			GlobalState.money -= cost
			popup.show_message("Оплата ЖКУ −" + str(cost))
			event_triggered.emit(ev, {"cost": cost})
		"client_rush":
			popup.show_message("Ярмарка! Больше клиентов")
			event_triggered.emit(ev, {})
		"police_razzia":
			popup.show_message("Полиция! Проверка документов")
			event_triggered.emit(ev, {})
		"mafia_visit":
			popup.show_message("Крыша требует платеж")
			event_triggered.emit(ev, {})
		"power_outage":
			popup.show_message("Отключение электричества")
			TimeManager.seconds_per_game_minute *= 2
			await get_tree().create_timer(30.0).timeout
			TimeManager.seconds_per_game_minute /= 2
			event_triggered.emit(ev, {})
