extends Node
@onready var sound_get: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sound_spawn: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sound_bonus_up: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sound_bonus_down: AudioStreamPlayer = AudioStreamPlayer.new()
# Сигналы
signal new_order(order_data)
signal order_completed(order_data, price)
signal order_rejected(order_data)

# Текущий активный заказ
var current_order: Dictionary = {}

# Настройки
var min_generation_delay: float = 2.0 # Задержка перед генерацией нового заказа в секундах
var can_generate: bool = true

func _ready() -> void:
	sound_get.stream = load("res://Sound/get_money.mp3")
	sound_get.bus = "&Sfx"
	sound_spawn.stream= load("res://Sound/order_spawned.mp3")
	sound_spawn.bus = "&Sfx"
	sound_bonus_up.stream = load("res://Sound/minus_bonus.mp3")
	sound_bonus_up.bus = "&Sfx"
	sound_bonus_down.stream= load("res://Sound/minus_bonus.mp3")
	sound_bonus_down.bus = "&Sfx"
	# Генерируем первый заказ после небольшой задержки
	get_tree().create_timer(1.0).timeout.connect(generate_random_order)

# Генерирует новый случайный заказ
func generate_random_order() -> void:
	# Если уже есть активный заказ, не генерируем новый
	if not current_order.is_empty():
		return
	
	# Выбираем категорию клиента на основе репутации
	var client_category = _select_client_category()
	
	# Выбираем случайного клиента из категории
	var client = _select_random_client(client_category)
	
	if not client.is_empty():
		_create_order_for_client(client)

# Создает заказ от конкретного клиента
func _create_order_for_client(client: Dictionary) -> void:
	# Выбираем продукт из предпочтений клиента
	var preferred_products = client.get("preferred_products", [])
	

	if (str(get_tree().get_current_scene()).split(':')[0] != "Main"): 
		print(get_tree().get_current_scene())
		get_tree().create_timer(min_generation_delay).timeout.connect(func(): generate_random_order())
		return
	# Фильтруем по доступным
	var available_products = []
	for prod_id in preferred_products:
		if prod_id in DataService.visible_recipes:
			available_products.append(prod_id)
	
	# Если нет доступных, используем любой доступный продукт
	if available_products.size() == 0:
		available_products = DataService.visible_recipes.filter(func(recipe_id):
			var recipe = DataService.find_recipe_by_product(recipe_id)
			return recipe.get("type", "") == "final_product"
		)
	
	# Если все еще нет доступных продуктов, пропускаем
	if available_products.size() == 0:
		return
	
	# Выбираем случайный продукт
	var product_id = available_products[randi() % available_products.size()]
	
	# Создаем заказ
	var order = {
		"client": client,
		"product_id": product_id,
		"required_quality": client.get("required_quality", 0),
		"price_sensitivity": client.get("price_sensitivity", 1.0),
		"alternative_chance": client.get("alternative_chance", 0.5),
		"discount_chance": client.get("discount_chance", 0.5)
	}
	
	# Сохраняем как текущий заказ
	current_order = order
	
	# Уведомляем о новом заказе
	get_tree().get_current_scene().add_child(sound_spawn)
	sound_spawn.play()
	new_order.emit(order)

# Выполнить заказ
func complete_order(price: int) -> void:
	if current_order.is_empty():
		return
	
	# Обновляем игровое состояние
	GlobalState.money += price
	GlobalState.stats["total_income"] += price
	
	# Рассчитываем прирост репутации
	var rep_gain = maxi(1, price / 50)
	GlobalState.reputation += rep_gain
	if rep_gain > 0:
		get_tree().get_current_scene().add_child(sound_bonus_up)
		sound_bonus_up.play()
	else:
		get_tree().get_current_scene().add_child(sound_bonus_down)
		sound_bonus_down.play()
	
	# Обновляем статистику
	GlobalState.stats["customers_served"] += 1
	
	# Уведомляем о выполнении заказа
	get_tree().get_current_scene().add_child(sound_get)
	#print (sound_get.get_parent())
	sound_get.play()
	
	order_completed.emit(current_order, price)
	
	# Очищаем текущий заказ
	var old_order = current_order
	current_order = {}
	
	# Планируем генерацию нового заказа с задержкой
	get_tree().create_timer(min_generation_delay).timeout.connect(func(): generate_random_order())

# Отклонить заказ
func reject_order() -> void:
	if current_order.is_empty():
		return
	
	# Небольшой штраф репутации за отклонение заказа
	GlobalState.reputation = max(0, GlobalState.reputation - 1)
	get_tree().get_current_scene().add_child(sound_bonus_down)
	sound_bonus_down.play()
	# Увеличиваем счетчик проваленных заказов
	GlobalState.stats["failed_orders"] += 1
	
	# Уведомляем об отклонении заказа
	order_rejected.emit(current_order)
	
	# Очищаем текущий заказ
	var old_order = current_order
	current_order = {}
	
	# Планируем генерацию нового заказа с задержкой
	get_tree().create_timer(min_generation_delay).timeout.connect(func(): generate_random_order())

# Вспомогательные функции для выбора клиентов
func _select_client_category() -> String:
	var rep = GlobalState.reputation
	
	if randf() < clamp(rep / 200.0, 0.05, 0.6):
		return "rich"
	elif randf() < 0.4:
		return "middle"
	else:
		return "poor"

func _select_random_client(category: String) -> Dictionary:
	var clients = DataService.customers.get(category, [])
	
	if clients.size() == 0:
		return {}
	
	return clients[randi() % clients.size()]

# Проверяет, подходит ли продукт для текущего заказа
func can_fulfill_with_product(product_card: Card) -> bool:
	if current_order.is_empty():
		return false
	
	# Проверяем ID продукта
	var required_id = current_order.get("product_id", "")
	var product_id = product_card.item_data.get("id", "")
	
	# Проверяем соответствие продукта
	if product_id != required_id:
		# Может быть, клиент согласится на альтернативу?
		var alt_chance = current_order.get("alternative_chance", 0.5)
		if randf() > alt_chance:
			return false
	
	# Проверяем качество
	var required_quality = current_order.get("required_quality", 0)
	var product_quality = product_card.get_quality()
	
	if product_quality < required_quality:
		# забиваем пока что на это
		var discount_chance = current_order.get("discount_chance", 0.5)
		if randf() > discount_chance:
			return true
	
	return true

# Рассчитывает цену продажи для текущего заказа
func calculate_price(product_card: Card) -> int:
	if current_order.is_empty():
		return 0
		
	var base_price = 0
	
	# Получаем базовую цену из данных продукта
	if product_card.item_data.has("sell_prices"):
		var quality = product_card.get_quality()
		var prices = product_card.item_data["sell_prices"]
		if quality >= 0 and quality < prices.size():
			base_price = prices[quality]
	
	# Применяем модификаторы
	var price_mod = 1.0
	
	# Разница в качестве
	var required_quality = current_order.get("required_quality", 0)
	var product_quality = product_card.get_quality()
	
	if product_quality > required_quality:
		# Бонус за высокое качество
		price_mod *= 1.2
	elif product_quality < required_quality:
		# Штраф за низкое качество
		price_mod *= 0.7
	
	# Чувствительность клиента к цене
	var sensitivity = current_order.get("price_sensitivity", 1.0)
	price_mod *= sensitivity
	
	# Рассчитываем итоговую цену
	var final_price = roundi(base_price * price_mod)
	
	return final_price
