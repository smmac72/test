class_name CustomerManager
extends Node

# Сигналы
signal customer_arrived(customer_data)
signal customer_left(customer_id, satisfied)
signal reputation_changed(new_reputation, change_reason)
signal special_event_triggered(event_data)

# Константы для категорий клиентов
enum CustomerCategory { POOR, MIDDLE, RICH }

# Список и очередь клиентов
var active_customers: Dictionary = {}  # id -> data
var customer_queue: Array = []
var regular_customers: Dictionary = {}  # id -> data

# Данные клиентов
var customer_templates: Dictionary = {}
var all_products: Dictionary = {}

# Временная система
var day_time: String = "morning"  # morning, day, evening, night
var current_day: int = 1
var customer_spawn_timer: Timer
var spawn_paused: bool = false

# Репутация
var reputation: float = 50.0  # 0-100

# Хранение продуктов для продажи
var storage_products: Dictionary = {}  # product_id_quality -> {count, price_modifier}

# Ссылки на другие системы
@onready var config_manager: ConfigManager = $"/root/ConfigM"
@onready var game_manager: GameManager = $"/root/GM"
@onready var production_manager: ProductionManager = $"/root/PM"
@onready var save_manager: SaveManager = $"/root/SM"

# Инициализация
func _ready() -> void:
	# Регистрируем систему в SaveManager
	if save_manager:
		save_manager.register_system("customer", self)
	
	# Создаем таймер генерации клиентов
	customer_spawn_timer = Timer.new()
	add_child(customer_spawn_timer)
	customer_spawn_timer.connect("timeout", _on_spawn_timer_timeout)
	
	# Подключаем сигналы
	if game_manager:
		game_manager.connect("day_changed", _on_day_changed)
		game_manager.connect("time_of_day_changed", _on_time_of_day_changed)
	
	# Загружаем конфигурации клиентов
	_load_customer_templates()
	
	# Загружаем информацию о продуктах
	_load_products_info()

# Загрузка шаблонов клиентов
func _load_customer_templates() -> void:
	# Загружаем JSON с шаблонами клиентов
	var json_data = config_manager.load_json_file("res://data/configs/customers.json")
	if json_data == null:
		push_error("Не удалось загрузить шаблоны клиентов")
		return
	
	# Обрабатываем данные клиентов
	for category_name in json_data:
		var category = CustomerCategory.POOR
		match category_name:
			"poor": category = CustomerCategory.POOR
			"middle": category = CustomerCategory.MIDDLE
			"rich": category = CustomerCategory.RICH
		
		for customer in json_data[category_name]:
			var id = customer.get("id", "")
			customer_templates[id] = {
				"id": id,
				"name": customer.get("name", "Клиент"),
				"category": category,
				"visual": customer.get("visual", "default"),
				"preferred_products": customer.get("preferred_products", []),
				"required_quality": customer.get("required_quality", 0),
				"price_sensitivity": customer.get("price_sensitivity", 1.0),
				"alternative_chance": customer.get("alternative_chance", 0.5),
				"discount_chance": customer.get("discount_chance", 0.5),
				"visit": customer.get("visit", {"type": "random", "chance": 0.2})
			}
			
			# Если это постоянный клиент, добавляем в список постоянных
			if customer.get("visit", {}).get("type", "") == "regular":
				regular_customers[id] = customer_templates[id]
	
	print("Загружено шаблонов клиентов: ", customer_templates.size())

# Загрузка информации о продуктах
func _load_products_info() -> void:
	# Получаем все конечные продукты от производственного менеджера
	var samogon_products = production_manager.get_products_by_type("samogon", true)
	var beer_products = production_manager.get_products_by_type("beer", true)
	var wine_products = production_manager.get_products_by_type("wine", true)
	
	# Объединяем все продукты в один словарь
	for product in samogon_products + beer_products + wine_products:
		all_products[product.id] = {
			"id": product.id,
			"name": product.name,
			"production_type": product.production_type,
			"sell_prices": product.sell_prices,
			"description": product.description
		}

# Запуск генерации клиентов
func start_customer_generation() -> void:
	# Настраиваем таймер в зависимости от времени суток
	_update_spawn_timer()
	customer_spawn_timer.start()

# Обновление таймера генерации клиентов
func _update_spawn_timer() -> void:
	var base_time = 0.0
	
	# Частота появления клиентов зависит от времени суток
	match day_time:
		"morning":
			base_time = 30.0  # раз в 30 секунд утром
		"day":
			base_time = 15.0  # раз в 15 секунд днем
		"evening":
			base_time = 10.0  # раз в 10 секунд вечером
		"night":
			base_time = 60.0  # раз в 60 секунд ночью
	
	# Репутация влияет на частоту появления клиентов
	var reputation_multiplier = 1.0 - (reputation / 200.0)  # от 1.0 до 0.5
	
	# Итоговое время между появлениями клиентов
	var spawn_time = base_time * reputation_multiplier
	
	# Обновляем таймер
	customer_spawn_timer.wait_time = spawn_time

# Обработчик таймера генерации клиентов
func _on_spawn_timer_timeout() -> void:
	if spawn_paused:
		return
	
	# Генерируем случайное число для определения появления клиента
	var rand = randf()
	
	# Проверяем регулярных клиентов сначала
	var regular_customer = _check_regular_customers()
	if regular_customer:
		# Создаем регулярного клиента
		emit_signal("customer_arrived", regular_customer)
		return
	
	# Базовый шанс появления случайного клиента
	var base_chance = 0.4
	
	# Репутация увеличивает шанс появления
	var reputation_bonus = reputation / 200.0  # от 0.0 до 0.5
	
	# Время суток влияет на шанс появления
	var time_multiplier = 1.0
	match day_time:
		"morning":
			time_multiplier = 0.7
		"day":
			time_multiplier = 1.0
		"evening":
			time_multiplier = 1.5
		"night":
			time_multiplier = 0.3
	
	# Итоговый шанс появления клиента
	var spawn_chance = (base_chance + reputation_bonus) * time_multiplier
	
	if rand < spawn_chance:
		# Генерируем и отправляем нового клиента
		var customer_data = generate_random_customer()
		emit_signal("customer_arrived", customer_data)

# Проверка появления регулярных клиентов
func _check_regular_customers() -> Dictionary:
	# Проверяем всех регулярных клиентов
	for id in regular_customers:
		var customer = regular_customers[id]
		var visit_data = customer.get("visit", {})
		
		# Проверяем день недели
		if "days" in visit_data:
			var days = visit_data.get("days", [])
			var weekday = (current_day - 1) % 7 + 1  # 1-7 (пн-вс)
			if not weekday in days:
				continue
		
		# Проверяем время суток
		if "time" in visit_data:
			var visit_time = visit_data.get("time", "")
			var hour = _time_string_to_hour(visit_time)
			var current_hour = _day_time_to_hour_range(day_time)
			
			# Если текущее время не соответствует времени визита, пропускаем
			if hour < current_hour[0] or hour > current_hour[1]:
				continue
		
		# Если все условия выполнены, возвращаем данные клиента
		return _prepare_customer_data(customer)
	
	return {}

# Генерация случайного клиента
func generate_random_customer() -> Dictionary:
	# Определяем категорию клиента на основе репутации
	var category_weights = {
		CustomerCategory.POOR: 0.7 - (reputation / 200.0),   # от 0.7 до 0.2
		CustomerCategory.MIDDLE: 0.25,
		CustomerCategory.RICH: 0.05 + (reputation / 200.0)   # от 0.05 до 0.55
	}
	
	# Нормализуем веса
	var total_weight = 0.0
	for cat in category_weights:
		total_weight += category_weights[cat]
	
	for cat in category_weights:
		category_weights[cat] /= total_weight
	
	# Выбираем категорию
	var rand = randf()
	var accumulated = 0.0
	var selected_category = CustomerCategory.POOR
	
	for cat in category_weights:
		accumulated += category_weights[cat]
		if rand <= accumulated:
			selected_category = cat
			break
	
	# Собираем подходящие шаблоны для выбранной категории
	var suitable_templates = []
	for id in customer_templates:
		var template = customer_templates[id]
		if template.get("category", CustomerCategory.POOR) == selected_category:
			suitable_templates.append(template)
	
	# Если нет подходящих шаблонов, возвращаем базовый
	if suitable_templates.size() == 0:
		return _generate_fallback_customer(selected_category)
	
	# Выбираем случайный шаблон
	var template = suitable_templates[randi() % suitable_templates.size()]
	
	# Готовим данные клиента
	return _prepare_customer_data(template)

# Генерация резервного клиента, если нет подходящих шаблонов
func _generate_fallback_customer(category: int) -> Dictionary:
	var names = ["Иван", "Петр", "Мария", "Анна", "Алексей", "Сергей", "Ольга", "Екатерина"]
	var name = names[randi() % names.size()]
	
	var template = {
		"id": "fallback_" + str(randi()),
		"name": name,
		"category": category,
		"visual": "default_" + str(category),
		"preferred_products": [],
		"required_quality": 0 if category == CustomerCategory.POOR else (1 if category == CustomerCategory.MIDDLE else 2),
		"price_sensitivity": 1.5 if category == CustomerCategory.POOR else (1.0 if category == CustomerCategory.MIDDLE else 0.7),
		"alternative_chance": 0.7 if category == CustomerCategory.POOR else (0.5 if category == CustomerCategory.MIDDLE else 0.3),
		"discount_chance": 0.8 if category == CustomerCategory.POOR else (0.5 if category == CustomerCategory.MIDDLE else 0.2)
	}
	
	return _prepare_customer_data(template)

# Подготовка данных клиента для отправки
func _prepare_customer_data(template: Dictionary) -> Dictionary:
	# Копируем шаблон
	var customer_data = template.duplicate(true)
	
	# Добавляем уникальный идентификатор визита
	customer_data["customer_id"] = customer_data["id"] + "_" + str(randi())
	
	# Определяем запрос клиента
	customer_data["request"] = _generate_customer_request(customer_data)
	
	# Добавляем клиента в активные
	active_customers[customer_data["customer_id"]] = customer_data
	
	return customer_data

# Генерация запроса клиента
func _generate_customer_request(customer_data: Dictionary) -> Dictionary:
	var request = {
		"type": "specific",  # specific или abstract
		"product_id": "",
		"required_quality": customer_data.get("required_quality", 0),
		"max_price": 0,
		"description": ""
	}
	
	# Определяем тип запроса (конкретный продукт или абстрактный)
	var is_abstract = randf() < 0.3  # 30% шанс абстрактного запроса
	
	if is_abstract:
		# Абстрактный запрос (например, "что-то крепкое" или "что-то сладкое")
		request["type"] = "abstract"
		
		var abstract_types = ["крепкое", "сладкое", "фруктовое", "ароматное", "дешевое", "премиальное"]
		var selected_type = abstract_types[randi() % abstract_types.size()]
		
		request["description"] = "Мне бы что-нибудь " + selected_type
		
		# Определяем продукты, подходящие под этот запрос
		request["matching_products"] = _get_matching_products_for_abstract(selected_type)
	else:
		# Конкретный запрос на определенный продукт
		request["type"] = "specific"
		
		# Выбираем продукт из предпочтений или случайно
		var preferred_products = customer_data.get("preferred_products", [])
		var product_id = ""
		
		if preferred_products.size() > 0 and randf() < 0.7:  # 70% шанс выбрать из предпочтений
			product_id = preferred_products[randi() % preferred_products.size()]
		else:
			# Выбираем случайный продукт из доступных
			var available_ids = all_products.keys()
			if available_ids.size() > 0:
				product_id = available_ids[randi() % available_ids.size()]
		
		request["product_id"] = product_id
		
		# Если у нас есть информация о продукте, заполняем дополнительные данные
		if product_id in all_products:
			var product = all_products[product_id]
			var quality = request["required_quality"]
			
			# Определяем максимальную цену, которую клиент готов заплатить
			var base_price = 0
			if quality < product["sell_prices"].size():
				base_price = product["sell_prices"][quality]
			
			# Наценка в зависимости от категории клиента
			var price_modifier = customer_data.get("price_sensitivity", 1.0)
			request["max_price"] = int(base_price * (1.0 + (1.0 - price_modifier)))
			
			# Описание запроса
			request["description"] = "Мне нужен " + product["name"]
			if quality > 0:
				request["description"] += " хорошего качества"
		else:
			# Если продукт не найден, генерируем абстрактный запрос
			return _generate_customer_request(customer_data)
	
	return request

# Получение продуктов, подходящих под абстрактный запрос
func _get_matching_products_for_abstract(abstract_type: String) -> Array:
	var matching_products = []
	
	match abstract_type:
		"крепкое":
			# Подходят все дистилляты
			for id in all_products:
				var product = all_products[id]
				if product["production_type"] == "samogon":
					matching_products.append(id)
		"сладкое":
			# Подходят настойки и некоторые виды вина
			for id in all_products:
				var product = all_products[id]
				if "настойка" in product["name"].to_lower() or "ликер" in product["name"].to_lower() or "десертное" in product["name"].to_lower():
					matching_products.append(id)
		"фруктовое":
			# Подходят фруктовые дистилляты и вина
			for id in all_products:
				var product = all_products[id]
				var name = product["name"].to_lower()
				if "яблоч" in name or "груш" in name or "слив" in name or "вишн" in name or "малин" in name or "фрукт" in name:
					matching_products.append(id)
		"ароматное":
			# Подходят ароматизированные напитки
			for id in all_products:
				var product = all_products[id]
				var name = product["name"].to_lower()
				if "аромат" in product["description"].to_lower() or "пряное" in name or "специя" in product["description"].to_lower():
					matching_products.append(id)
		"дешевое":
			# Подходят напитки низкой цены
			for id in all_products:
				var product = all_products[id]
				if product["sell_prices"][0] < 30:
					matching_products.append(id)
		"премиальное":
			# Подходят дорогие напитки
			for id in all_products:
				var product = all_products[id]
				if product["sell_prices"].size() > 3 and product["sell_prices"][3] > 50:
					matching_products.append(id)
	
	return matching_products

# Предложение продукта клиенту
func offer_product_to_customer(customer_id: String, product_id: String, quality: int, price: int) -> bool:
	if not customer_id in active_customers:
		return false
	
	var customer = active_customers[customer_id]
	var request = customer.get("request", {})
	
	# Проверяем соответствие продукта запросу
	var product_matches = false
	var quality_acceptable = false
	var price_acceptable = false
	
	# Проверка соответствия продукта
	if request["type"] == "specific":
		product_matches = (request["product_id"] == product_id)
	else:  # abstract
		product_matches = (product_id in request.get("matching_products", []))
	
	# Проверка качества
	quality_acceptable = (quality >= request["required_quality"])
	
	# Проверка цены
	var max_price = request["max_price"]
	price_acceptable = (price <= max_price)
	
	# Все требования выполнены
	if product_matches and quality_acceptable and price_acceptable:
		# Клиент соглашается на покупку
		_handle_successful_sale(customer, product_id, quality, price)
		return true
	
	# Проверяем возможность предложения альтернативы
	if not product_matches:
		var alternative_chance = customer.get("alternative_chance", 0.5)
		if randf() < alternative_chance:
			# Клиент соглашается на альтернативный продукт
			_handle_successful_sale(customer, product_id, quality, price)
			return true
	
	# Проверяем возможность скидки, если проблема в цене
	if product_matches and quality_acceptable and not price_acceptable:
		var discount_chance = customer.get("discount_chance", 0.5)
		if randf() < discount_chance:
			# Клиент соглашается по более низкой цене
			_handle_successful_sale(customer, product_id, quality, max_price)
			return true
	
	# Клиент отказывается
	_handle_rejected_sale(customer, product_id, quality, price)
	return false

# Обработка успешной продажи
func _handle_successful_sale(customer: Dictionary, product_id: String, quality: int, price: int) -> void:
	var category = customer.get("category", CustomerCategory.POOR)
	
	# Определяем изменение репутации в зависимости от категории клиента
	var reputation_change = 0.0
	match category:
		CustomerCategory.POOR:
			reputation_change = 0.5
		CustomerCategory.MIDDLE:
			reputation_change = 1.0
		CustomerCategory.RICH:
			reputation_change = 2.0
	
	# Если качество выше требуемого, дополнительный бонус
	if quality > customer.get("required_quality", 0):
		reputation_change += (quality - customer.get("required_quality", 0)) * 0.5
	
	# Применяем изменение репутации
	change_reputation(reputation_change, "Успешная продажа")

# Обработка отказа от покупки
func _handle_rejected_sale(customer: Dictionary, product_id: String, quality: int, price: int) -> void:
	var category = customer.get("category", CustomerCategory.POOR)
	
	# Определяем изменение репутации в зависимости от категории клиента
	var reputation_change = 0.0
	match category:
		CustomerCategory.POOR:
			reputation_change = -0.2
		CustomerCategory.MIDDLE:
			reputation_change = -0.5
		CustomerCategory.RICH:
			reputation_change = -1.0
	
	# Применяем изменение репутации
	change_reputation(reputation_change, "Отказ от покупки")

# Изменение репутации
func change_reputation(amount: float, reason: String = "") -> void:
	reputation = clamp(reputation + amount, 0.0, 100.0)
	emit_signal("reputation_changed", reputation, reason)
	
	# Обновляем таймер появления клиентов
	_update_spawn_timer()
	
	# Сохраняем игру при значительных изменениях репутации
	if abs(amount) >= 1.0 and save_manager:
		save_manager.save_game()

# Добавление клиента в очередь
func add_to_queue(customer_data: Dictionary) -> void:
	customer_queue.append(customer_data)

# Получение следующего клиента из очереди
func get_next_from_queue() -> Dictionary:
	if customer_queue.size() > 0:
		return customer_queue.pop_front()
	return {}

# Обработчик изменения дня
func _on_day_changed(new_day: int) -> void:
	current_day = new_day
	
	# Сбрасываем очередь клиентов
	customer_queue.clear()
	
	# Генерируем новых регулярных клиентов на новый день
	_update_regular_customers()

# Обработчик изменения времени суток
func _on_time_of_day_changed(new_time: String) -> void:
	day_time = new_time
	
	# Обновляем таймер появления клиентов
	_update_spawn_timer()

# Обновление списка регулярных клиентов
func _update_regular_customers() -> void:
	# Обновляем список регулярных клиентов на основе конфигурации
	regular_customers.clear()
	
	for id in customer_templates:
		var template = customer_templates[id]
		var visit_data = template.get("visit", {})
		
		if visit_data.get("type", "") == "regular":
			regular_customers[id] = template

# Вспомогательные функции для работы со временем
func _time_string_to_hour(time_str: String) -> int:
	# Конвертирует строку времени (например, "18:00") в час (18)
	var parts = time_str.split(":")
	if parts.size() >= 1:
		return int(parts[0])
	return 12  # по умолчанию полдень

func _day_time_to_hour_range(time_of_day: String) -> Array:
	# Конвертирует время суток в диапазон часов
	match time_of_day:
		"morning":
			return [6, 11]
		"day":
			return [12, 17]
		"evening":
			return [18, 23]
		"night":
			return [0, 5]
	return [0, 23]  # весь день по умолчанию

# Добавление продукта на склад
func add_product_to_storage(product_id: String, quality: int, count: int = 1, price_modifier: float = 1.0) -> void:
	var key = product_id + "_" + str(quality)
	
	if key in storage_products:
		storage_products[key]["count"] += count
	else:
		storage_products[key] = {
			"count": count,
			"price_modifier": price_modifier
		}

# Получение данных продукта со склада
func get_storage_product(product_id: String, quality: int) -> Dictionary:
	var key = product_id + "_" + str(quality)
	
	if key in storage_products:
		return storage_products[key]
	
	return {}

# Удаление продукта со склада
func remove_product_from_storage(product_id: String, quality: int, count: int = 1) -> bool:
	var key = product_id + "_" + str(quality)
	
	if key in storage_products:
		storage_products[key]["count"] -= count
		
		if storage_products[key]["count"] <= 0:
			# Удаляем продукт, если количество стало 0 или меньше
			storage_products.erase(key)
		
		return true
	
	return false

# Обновление модификатора цены продукта
func update_product_price_modifier(product_id: String, quality: int, new_modifier: float) -> bool:
	var key = product_id + "_" + str(quality)
	
	if key in storage_products:
		storage_products[key]["price_modifier"] = new_modifier
		return true
	
	return false

# Интерфейс для SaveManager - получение данных для сохранения
func get_save_data() -> Dictionary:
	return {
		"reputation": reputation,
		"storage_products": storage_products,
		"day_time": day_time,
		"current_day": current_day
	}

# Интерфейс для SaveManager - загрузка данных из сохранения
func load_save_data(data: Dictionary) -> void:
	reputation = data.get("reputation", 50.0)
	
	if "storage_products" in data:
		storage_products = data.get("storage_products", {})
	
	if "day_time" in data:
		day_time = data.get("day_time", "morning")
	
	if "current_day" in data:
		current_day = data.get("current_day", 1)
	
	print("CustomerManager: Загрузка сохранения завершена")
