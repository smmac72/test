extends Node

# Сигналы
signal event_triggered(event_name, payload)
signal event_completed(event_name, result)

# Типы событий
var daily_events = ["utilities_payment"]  # События которые происходят каждый день
var random_events = [  # События с шансом появления
	"police_inspection",    # Проверка полиции
	"mafia_visit",          # Визит местной "крыши"
	"power_outage",         # Отключение электричества
	"supplier_discount",    # Скидка на ингредиенты
	"ingredient_shortage",  # Дефицит какого-то ингредиента
	"customer_rush",        # Наплыв клиентов
	"health_inspection"     # Проверка санитарных норм
]

# Вероятности событий (зависят от репутации)
var event_probabilities = {
	"police_inspection": 0.05,
	"mafia_visit": 0.04,
	"power_outage": 0.03,
	"supplier_discount": 0.07,
	"ingredient_shortage": 0.06,
	"customer_rush": 0.08,
	"health_inspection": 0.04
}

# Активные события
var active_events = {}  # имя_события -> данные

@onready var popup_manager = PopupManager

func _ready() -> void:
	# Подключаем обработку времени для периодической проверки событий
	TimeManager.hour_changed.connect(_on_hour_changed)
	TimeManager.day_changed.connect(_on_day_changed)

func _on_hour_changed(hour: int) -> void:
	# Проверяем случайные события каждый час
	#if hour >= 8 and hour <= 20:  # Только в рабочие часы
	#	_check_random_events()
	return

func _on_day_changed(_day: int) -> void:
	# Запускаем ежедневные события
	#for event_name in daily_events:
	#	_trigger_event(event_name)
	return

func _check_random_events() -> void:
	# Проверяем каждое случайное событие
	for event_name in random_events:
		var base_probability = event_probabilities.get(event_name, 0.0)
		var modified_probability = _calculate_event_probability(event_name, base_probability)
		
		if randf() < modified_probability:
			_trigger_event(event_name)
			break  # Только одно случайное событие за раз

func _calculate_event_probability(event_name: String, base_probability: float) -> float:
	# Модифицируем вероятность в зависимости от репутации и других факторов
	var modifier = 1.0
	
	# Высокая репутация снижает вероятность плохих событий
	if GlobalState.reputation > 150:
		match event_name:
			"police_inspection", "mafia_visit", "health_inspection":
				modifier = 0.5
	
	# Низкая репутация увеличивает вероятность плохих событий
	elif GlobalState.reputation < 50:
		match event_name:
			"police_inspection", "mafia_visit", "health_inspection":
				modifier = 2.0
	
	return base_probability * modifier

func _trigger_event(event_name: String) -> void:
	# Генерируем данные события
	var payload = _generate_event_data(event_name)
	
	# Добавляем в активные события
	active_events[event_name] = payload
	
	# Запускаем обработку события
	_process_event(event_name, payload)
	
	# Отправляем сигнал
	event_triggered.emit(event_name, payload)

func _generate_event_data(event_name: String) -> Dictionary:
	var data = {}
	
	match event_name:
		"utilities_payment":
			# Расчет стоимости коммунальных услуг
			var base_cost = 100
			var day_modifier = clampf(1.0 + GlobalState.current_day * 0.05, 1.0, 3.0)
			data["cost"] = int(base_cost * day_modifier)
		
		"police_inspection":
			# Данные полицейской проверки
			data["bribe_amount"] = 200 + GlobalState.current_day * 30
			data["fine_amount"] = 500 + GlobalState.current_day * 50
			data["reputation_loss"] = 20
		
		"mafia_visit":
			# Визит "крыши"
			data["protection_fee"] = 300 + GlobalState.current_day * 40
			data["damage_cost"] = 700 + GlobalState.current_day * 70
			data["reputation_boost"] = 10
		
		"power_outage":
			# Отключение электричества
			data["duration_minutes"] = 30 + randi() % 30  # 30-60 минут
			data["slowdown_factor"] = 0.5  # Замедление производства
		
		"supplier_discount":
			# Скидка от поставщика
			data["discount_percent"] = 20 + randi() % 30  # 20-50%
			data["ingredient_type"] = ["base", "mash_ingredient", "fermentation", "flavor"].pick_random()
			data["duration_days"] = 1 + randi() % 2  # 1-2 дня
		
		"ingredient_shortage":
			# Дефицит ингредиента
			var ingredient_categories = ["mash_ingredient", "fermentation", "flavor", "aging"]
			data["affected_type"] = ingredient_categories.pick_random()
			data["price_increase"] = 1.5 + randf() * 1.0  # 1.5-2.5x цена
			data["duration_days"] = 1 + randi() % 3  # 1-3 дня
		
		"customer_rush":
			# Наплыв клиентов
			data["customer_multiplier"] = 2.0 + randf()  # 2.0-3.0x клиентов
			data["duration_hours"] = 3 + randi() % 5  # 3-7 часов
		
		"health_inspection":
			# Проверка санитарных норм
			data["fine_amount"] = 400 + GlobalState.current_day * 40
			data["reputation_loss"] = 15
			data["bribe_amount"] = 250 + GlobalState.current_day * 25
	
	return data

func _process_event(event_name: String, payload: Dictionary) -> void:
	# Обработка события
	match event_name:
		"utilities_payment":
			var cost = payload["cost"]
			if GlobalState.money >= cost:
				GlobalState.money -= cost
				popup_manager.show_message("Оплата ЖКУ: -" + str(cost) + "₽", 3.0)
			else:
				# Не хватает денег на оплату
				popup_manager.show_dialog(
					"Оплата ЖКУ",
					"У вас недостаточно средств для оплаты (%d₽). Взять кредит на неделю?" % cost,
					[
						{"text": "Взять кредит", "callback": "_on_take_loan", "args": [cost]},
						{"text": "Отказаться", "callback": "_on_refuse_loan"}
					]
				)
		
		"police_inspection":
			popup_manager.show_dialog(
				"Полицейская проверка",
				"Полиция проводит проверку! Предложить взятку (%d₽) или пройти проверку?" % payload["bribe_amount"],
				[
					{"text": "Предложить взятку", "callback": "_on_police_bribe", "args": [payload]},
					{"text": "Пройти проверку", "callback": "_on_police_inspection", "args": [payload]}
				]
			)
		
		"mafia_visit":
			popup_manager.show_dialog(
				"Местная крыша",
				"Пришли ребята из местной 'крыши'. Требуют плату за защиту (%d₽)." % payload["protection_fee"],
				[
					{"text": "Заплатить", "callback": "_on_pay_protection", "args": [payload]},
					{"text": "Отказаться", "callback": "_on_refuse_protection", "args": [payload]}
				]
			)
		
		"power_outage":
			# Автоматически применяем эффект
			TimeManager.set_time_scale(GlobalState.game_speed * payload["slowdown_factor"])
			popup_manager.show_message("Отключение электричества на %d минут!" % payload["duration_minutes"], 5.0)
			
			# Отменяем эффект через некоторое время
			var timer = get_tree().create_timer(payload["duration_minutes"] * TimeManager.seconds_per_game_minute)
			timer.timeout.connect(func(): 
				TimeManager.set_time_scale(GlobalState.game_speed)
				popup_manager.show_message("Электричество восстановлено!", 3.0)
				_complete_event(event_name, {"success": true})
			)
		
		"supplier_discount", "ingredient_shortage", "customer_rush":
			# Информационные события, обрабатываются в соответствующих менеджерах
			popup_manager.show_message(_get_event_message(event_name, payload), 5.0)
			
			# Создаем таймер для завершения события
			var duration = 0.0
			if payload.has("duration_days"):
				duration = payload["duration_days"] * 24 * 60 * TimeManager.seconds_per_game_minute
			elif payload.has("duration_hours"):
				duration = payload["duration_hours"] * 60 * TimeManager.seconds_per_game_minute
			
			if duration > 0:
				var timer = get_tree().create_timer(duration)
				timer.timeout.connect(func(): _complete_event(event_name, {"success": true}))
		
		"health_inspection":
			popup_manager.show_dialog(
				"Проверка санитарных норм",
				"Санитарная инспекция проводит проверку! Предложить взятку (%d₽) или пройти проверку?" % payload["bribe_amount"],
				[
					{"text": "Предложить взятку", "callback": "_on_health_bribe", "args": [payload]},
					{"text": "Пройти проверку", "callback": "_on_health_inspection", "args": [payload]}
				]
			)

func _complete_event(event_name: String, result: Dictionary) -> void:
	# Удаляем из активных событий
	if active_events.has(event_name):
		active_events.erase(event_name)
	
	# Отправляем сигнал о завершении
	event_completed.emit(event_name, result)

func _get_event_message(event_name: String, payload: Dictionary) -> String:
	# Формирует сообщение для события
	match event_name:
		"utilities_payment":
			return "Оплата ЖКУ: -" + str(payload["cost"]) + "₽"
		
		"supplier_discount":
			return "Скидка %d%% на ингредиенты типа %s на %d дн." % [
				payload["discount_percent"], 
				_translate_type(payload["ingredient_type"]), 
				payload["duration_days"]
			]
		
		"ingredient_shortage":
			return "Дефицит ингредиентов типа %s. Цены выросли в %.1fx на %d дн." % [
				_translate_type(payload["affected_type"]), 
				payload["price_increase"], 
				payload["duration_days"]
			]
		
		"customer_rush":
			return "Наплыв клиентов в %.1fx на %d ч." % [
				payload["customer_multiplier"], 
				payload["duration_hours"]
			]
		
		"power_outage":
			return "Отключение электричества на %d мин. Производство замедлено." % payload["duration_minutes"]
	
	return "Событие: " + event_name

func _translate_type(type_name: String) -> String:
	# Переводит технические названия типов на русский
	match type_name:
		"base": return "основы"
		"mash_ingredient": return "браги"
		"fermentation": return "ферментации"
		"flavor": return "вкусовые"
		"aging": return "выдержки"
		"beer_additive": return "добавки для пива"
		"wine_additive": return "добавки для вина"
	
	return type_name

# Обработчики ответов на события
func _on_take_loan(cost: int) -> void:
	GlobalState.take_loan(cost)
	popup_manager.show_message("Вы взяли кредит на неделю", 3.0)
	_complete_event("utilities_payment", {"success": true, "loan_taken": true})

func _on_refuse_loan() -> void:
	popup_manager.show_message("Вы отказались от кредита", 3.0)
	_complete_event("utilities_payment", {"success": false, "loan_taken": false})
	
	# Проверка условия поражения - нет возможности производить продукцию
	# Это будет проверяться в GameManager

func _on_police_bribe(payload: Dictionary) -> void:
	var bribe_amount = payload["bribe_amount"]
	
	if GlobalState.money >= bribe_amount:
		GlobalState.money -= bribe_amount
		popup_manager.show_message("Взятка принята. Полиция ушла.", 3.0)
		_complete_event("police_inspection", {"success": true, "bribed": true})
	else:
		popup_manager.show_message("Недостаточно денег для взятки!", 3.0)
		_on_police_inspection(payload)  # Автоматически переходим к проверке

func _on_police_inspection(payload: Dictionary) -> void:
	# Шанс на штраф зависит от репутации
	var fine_chance = clampf(1.0 - GlobalState.reputation / 200.0, 0.1, 0.9)
	
	if randf() < fine_chance:
		# Штраф
		var fine_amount = payload["fine_amount"]
		GlobalState.money -= fine_amount
		GlobalState.reputation -= payload["reputation_loss"]
		
		popup_manager.show_message("Проверка выявила нарушения. Штраф: -" + str(fine_amount) + "₽", 3.0)
		_complete_event("police_inspection", {"success": false, "fined": true, "amount": fine_amount})
	else:
		popup_manager.show_message("Проверка пройдена успешно!", 3.0)
		_complete_event("police_inspection", {"success": true, "fined": false})

func _on_pay_protection(payload: Dictionary) -> void:
	var fee = payload["protection_fee"]
	
	if GlobalState.money >= fee:
		GlobalState.money -= fee
		GlobalState.reputation += payload["reputation_boost"]
		
		popup_manager.show_message("Вы заплатили за защиту. Репутация повышена.", 3.0)
		_complete_event("mafia_visit", {"success": true, "paid": true})
	else:
		popup_manager.show_message("Недостаточно денег для оплаты!", 3.0)
		_on_refuse_protection(payload)  # Автоматически переходим к отказу

func _on_refuse_protection(payload: Dictionary) -> void:
	# Наносят ущерб
	var damage_cost = payload["damage_cost"]
	GlobalState.money -= damage_cost
	
	popup_manager.show_message("Вам нанесли ущерб на " + str(damage_cost) + "₽!", 3.0)
	_complete_event("mafia_visit", {"success": false, "paid": false, "damage": damage_cost})

func _on_health_bribe(payload: Dictionary) -> void:
	var bribe_amount = payload["bribe_amount"]
	
	if GlobalState.money >= bribe_amount:
		GlobalState.money -= bribe_amount
		popup_manager.show_message("Взятка принята. Инспекция ушла.", 3.0)
		_complete_event("health_inspection", {"success": true, "bribed": true})
	else:
		popup_manager.show_message("Недостаточно денег для взятки!", 3.0)
		_on_health_inspection(payload)  # Автоматически переходим к проверке

func _on_health_inspection(payload: Dictionary) -> void:
	# Шанс на штраф зависит от репутации
	var fine_chance = clampf(1.0 - GlobalState.reputation / 200.0, 0.2, 0.8)
	
	if randf() < fine_chance:
		# Штраф
		var fine_amount = payload["fine_amount"]
		GlobalState.money -= fine_amount
		GlobalState.reputation -= payload["reputation_loss"]
		
		popup_manager.show_message("Проверка выявила нарушения санитарных норм. Штраф: -" + str(fine_amount) + "₽", 3.0)
		_complete_event("health_inspection", {"success": false, "fined": true, "amount": fine_amount})
	else:
		popup_manager.show_message("Санитарная проверка пройдена успешно!", 3.0)
		_complete_event("health_inspection", {"success": true, "fined": false})

# Вспомогательные методы
func is_event_active(event_name: String) -> bool:
	return active_events.has(event_name)

func get_active_events() -> Array:
	return active_events.keys()
