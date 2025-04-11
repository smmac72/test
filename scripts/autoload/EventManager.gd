class_name EventManager
extends Node

# Сигналы
signal event_triggered(event_data)
signal event_completed(event_id, result)

# Типы событий
enum EventType { POLICE, CRIMINAL, VIP_CLIENT, UTILITY_PAYMENT, RANDOM }

# Данные событий
var event_templates: Dictionary = {}
var active_events: Dictionary = {}
var daily_events: Array = []
var scheduled_events: Dictionary = {}  # день -> массив событий

# Ссылки на другие системы
@onready var config_manager: ConfigManager = $"/root/ConfigManager"
@onready var game_manager: GameManager = $"/root/GameManager"
@onready var customer_manager: CustomerManager = $"/root/CustomerManager"
@onready var time_manager: TimeManager = $"/root/TimeManager"

# Инициализация
func _ready() -> void:
	# Загружаем шаблоны событий
	load_event_templates()
	
	# Подключаем сигналы
	game_manager.connect("day_changed", _on_day_changed)

# Загрузка шаблонов событий
func load_event_templates() -> void:
	# Загружаем JSON с шаблонами событий
	var json_data = config_manager.load_json_file("res://data/configs/events.json")
	if json_data == null:
		push_error("Не удалось загрузить шаблоны событий")
		return
	
	# Обрабатываем данные событий
	for event_type in json_data:
		var type_enum = EventType.RANDOM
		match event_type:
			"police": type_enum = EventType.POLICE
			"criminal": type_enum = EventType.CRIMINAL
			"vip_client": type_enum = EventType.VIP_CLIENT
			"utility_payment": type_enum = EventType.UTILITY_PAYMENT
		
		for event in json_data[event_type]:
			var id = event.get("id", "")
			event_templates[id] = {
				"id": id,
				"name": event.get("name", "Событие"),
				"type": type_enum,
				"chance": event.get("chance", 0.1),
				"reputation_modifier": event.get("reputation_modifier", 0.0),
				"requirements": event.get("requirements", {}),
				"options": event.get("options", [])
			}
	
	print("Загружено шаблонов событий: ", event_templates.size())

# Генерация ежедневных событий
func generate_daily_events() -> void:
	# Очищаем список ежедневных событий
	daily_events.clear()
	
	# Добавляем обязательное событие - оплата коммунальных услуг
	add_utility_payment_event()
	
	# Проверяем запланированные события на текущий день
	check_scheduled_events()
	
	# Генерируем случайные события
	generate_random_events()

# Добавление события оплаты коммунальных услуг
func add_utility_payment_event() -> void:
	# Создаем событие оплаты
	var event_data = {
		"id": "utility_payment_" + str(game_manager.game_day),
		"name": "Оплата коммунальных услуг",
		"type": EventType.UTILITY_PAYMENT,
		"payment_amount": game_manager.utility_cost,
		"options": [
			{
				"id": "pay",
				"text": "Оплатить (" + str(game_manager.utility_cost) + "₽)",
				"requirements": {"money": game_manager.utility_cost},
				"success_chance": 1.0,
				"success": {
					"money": -game_manager.utility_cost,
					"message": "Вы оплатили коммунальные услуги."
				}
			},
			{
				"id": "take_loan",
				"text": "Взять займ",
				"requirements": {},
				"success_chance": 1.0,
				"success": {
					"loan": game_manager.utility_cost,
					"message": "Вы взяли займ для оплаты коммунальных услуг."
				}
			},
			{
				"id": "skip",
				"text": "Пропустить оплату",
				"requirements": {},
				"success_chance": 1.0,
				"success": {
					"reputation": -5,
					"message": "Вы пропустили оплату. Это может иметь последствия."
				}
			}
		]
	}
	
	# Добавляем в список ежедневных событий
	daily_events.append(event_data)
	
	# Запускаем событие
	trigger_event(event_data)

# Проверка запланированных событий
func check_scheduled_events() -> void:
	var current_day = game_manager.game_day
	
	if current_day in scheduled_events:
		for event_data in scheduled_events[current_day]:
			# Проверяем требования события
			if check_event_requirements(event_data):
				# Добавляем в список ежедневных событий
				daily_events.append(event_data)
				
				# Запускаем событие
				trigger_event(event_data)
		
		# Удаляем обработанные события
		scheduled_events.erase(current_day)

# Генерация случайных событий
func generate_random_events() -> void:
	# Получаем данные о репутации
	var reputation = customer_manager.reputation
	
	# Перебираем все шаблоны событий
	for id in event_templates:
		var template = event_templates[id]
		
		# Пропускаем события оплаты (они добавляются отдельно)
		if template.type == EventType.UTILITY_PAYMENT:
			continue
		
		# Вычисляем шанс события с учетом репутации
		var base_chance = template.get("chance", 0.1)
		var reputation_modifier = template.get("reputation_modifier", 0.0)
		var chance = base_chance + (reputation * reputation_modifier)
		
		# Генерируем случайное число
		var rand = randf()
		
		# Если выпало событие
		if rand < chance:
			# Проверяем требования события
			if check_event_requirements(template):
				# Создаем копию шаблона
				var event_data = template.duplicate(true)
				
				# Добавляем уникальный ID для этого экземпляра события
				event_data["instance_id"] = event_data["id"] + "_" + str(game_manager.game_day) + "_" + str(randi())
				
				# Добавляем в список ежедневных событий
				daily_events.append(event_data)
				
				# Запускаем событие
				trigger_event(event_data)

# Проверка требований события
func check_event_requirements(event_data: Dictionary) -> bool:
	var requirements = event_data.get("requirements", {})
	
	# Проверка требования по репутации
	if "reputation" in requirements:
		var required_reputation = requirements["reputation"]
		if customer_manager.reputation < required_reputation:
			return false
	
	# Проверка требования по деньгам
	if "money" in requirements:
		var required_money = requirements["money"]
		if game_manager.money < required_money:
			return false
	
	# Проверка требования по дню недели
	if "weekday" in requirements:
		var required_weekdays = requirements["weekday"]
		var current_weekday = time_manager.get_weekday()
		if not current_weekday in required_weekdays:
			return false
	
	# Проверка требования по времени суток
	if "time_of_day" in requirements:
		var required_times = requirements["time_of_day"]
		var current_time = time_manager.time_of_day_name
		if not current_time in required_times:
			return false
	
	return true

# Запуск события
func trigger_event(event_data: Dictionary) -> void:
	# Запоминаем активное событие
	var instance_id = event_data.get("instance_id", event_data["id"])
	active_events[instance_id] = event_data
	
	# Отправляем сигнал о событии
	emit_signal("event_triggered", event_data)
	
	# Создаем UI для события
	show_event_ui(event_data)

# Показ UI события
func show_event_ui(event_data: Dictionary) -> void:
	var event_dialog = preload("res://scenes/ui/EventDialog.tscn").instantiate()
	event_dialog.setup(event_data)
	event_dialog.connect("option_selected", _on_event_option_selected.bind(event_data))
	
	# Добавляем в основной UI
	var ui_layer = get_tree().get_nodes_in_group("ui_layer")
	if ui_layer.size() > 0:
		ui_layer[0].add_child(event_dialog)
	else:
		# Если не найден UI слой, добавляем прямо в дерево
		get_tree().current_scene.add_child(event_dialog)
	
	event_dialog.popup_centered()

# Обработчик выбора опции события
func _on_event_option_selected(option_id: String, event_data: Dictionary) -> void:
	# Находим данные опции
	var selected_option = null
	for option in event_data.get("options", []):
		if option.get("id", "") == option_id:
			selected_option = option
			break
	
	if selected_option == null:
		push_error("Не найдена опция с ID: " + option_id)
		return
	
	# Проверяем требования опции
	var requirements = selected_option.get("requirements", {})
	var requirements_met = true
	
	# Проверка требования по деньгам
	if "money" in requirements:
		var required_money = requirements["money"]
		if game_manager.money < required_money:
			requirements_met = false
	
	# Проверка требования по продуктам
	if "products" in requirements:
		var required_products = requirements["products"]
		var has_products = false
		
		for product_id in required_products:
			var product = customer_manager.all_products.get(product_id, null)
			if product != null:
				has_products = true
				break
		
		if not has_products:
			requirements_met = false
	
	# Если требования не выполнены, показываем сообщение
	if not requirements_met:
		# Показываем уведомление о невыполненных требованиях
		show_notification("Требования не выполнены!")
		return
	
	# Определяем успех или неудачу
	var success_chance = selected_option.get("success_chance", 1.0)
	var is_success = randf() < success_chance
	
	# Применяем результат
	var result = {}
	
	if is_success:
		result = selected_option.get("success", {})
	else:
		result = selected_option.get("failure", {})
	
	# Применяем изменения денег
	if "money" in result:
		game_manager.change_money(result["money"], event_data.get("name", "Событие"))
	
	# Применяем изменения репутации
	if "reputation" in result:
		customer_manager.change_reputation(result["reputation"], event_data.get("name", "Событие"))
	
	# Применяем займ
	if "loan" in result:
		game_manager.take_loan(result["loan"])
	
	# Показываем сообщение о результате
	if "message" in result:
		show_notification(result["message"])
	
	# Удаляем событие из активных
	var instance_id = event_data.get("instance_id", event_data["id"])
	active_events.erase(instance_id)
	
	# Отправляем сигнал о завершении события
	emit_signal("event_completed", event_data["id"], result)

# Планирование события на будущее
func schedule_event(event_id: String, days_from_now: int) -> void:
	if not event_id in event_templates:
		push_error("Не найден шаблон события с ID: " + event_id)
		return
	
	var target_day = game_manager.game_day + days_from_now
	
	if not target_day in scheduled_events:
		scheduled_events[target_day] = []
	
	scheduled_events[target_day].append(event_templates[event_id].duplicate(true))

# Обработчик смены дня
func _on_day_changed(day: int) -> void:
	# Генерируем события на новый день
	generate_daily_events()

# Запуск случайного события определенного типа
func trigger_random_event(type: int) -> void:
	# Собираем все шаблоны указанного типа
	var suitable_templates = []
	
	for id in event_templates:
		var template = event_templates[id]
		if template.type == type and check_event_requirements(template):
			suitable_templates.append(template)
	
	# Если не найдены подходящие шаблоны, выходим
	if suitable_templates.size() == 0:
		return
	
	# Выбираем случайный шаблон
	var template = suitable_templates[randi() % suitable_templates.size()]
	
	# Создаем копию шаблона
	var event_data = template.duplicate(true)
	
	# Добавляем уникальный ID для этого экземпляра события
	event_data["instance_id"] = event_data["id"] + "_" + str(game_manager.game_day) + "_" + str(randi())
	
	# Запускаем событие
	trigger_event(event_data)

# Показ уведомления
func show_notification(text: String) -> void:
	var notification = preload("res://scenes/ui/Notification.tscn").instantiate()
	notification.setup(text)
	
	# Добавляем в основной UI
	var ui_layer = get_tree().get_nodes_in_group("ui_layer")
	if ui_layer.size() > 0:
		ui_layer[0].add_child(notification)
	else:
		# Если не найден UI слой, добавляем прямо в дерево
		get_tree().current_scene.add_child(notification)
