extends Node
class_name Warehouse

# Структура склада
# {
#   id_продукта: {
#     "count": количество,
#     "quality": качество,
#     "data": полные данные о продукте
#   }
# }
var stock = {}

# Максимальное количество каждого продукта на складе
var max_item_capacity = 10

# Максимальное количество разных типов продуктов
var max_types_capacity = 20

# Сигналы
signal item_added(item_id, count, quality)
signal item_removed(item_id, count, quality)
signal storage_updated()

# Добавляет продукт на склад
func add_item(item_id: String, quality: int, count: int = 1) -> bool:
	# Проверяем, не превышен ли лимит типов
	if not stock.has(item_id) and stock.size() >= max_types_capacity:
		return false
	
	# Проверяем, не превышен ли лимит количества
	if stock.has(item_id):
		if stock[item_id]["count"] + count > max_item_capacity:
			return false
	
	# Получаем данные о продукте
	var item_data = DataService.find_item(item_id)
	if item_data.is_empty():
		return false
	
	# Добавляем или обновляем запись в складе
	if not stock.has(item_id):
		stock[item_id] = {
			"count": count,
			"quality": quality,
			"data": item_data
		}
	else:
		stock[item_id]["count"] += count
	
	# Уведомляем о добавлении продукта
	item_added.emit(item_id, count, quality)
	storage_updated.emit()
	
	return true

# Убирает продукт со склада
func remove_item(item_id: String, count: int = 1) -> bool:
	# Проверяем наличие продукта
	if not stock.has(item_id) or stock[item_id]["count"] < count:
		return false
	
	# Уменьшаем количество
	stock[item_id]["count"] -= count
	
	# Получаем качество для сигнала
	var quality = stock[item_id]["quality"]
	
	# Если количество стало нулевым, удаляем запись
	if stock[item_id]["count"] <= 0:
		stock.erase(item_id)
	
	# Уведомляем об удалении продукта
	item_removed.emit(item_id, count, quality)
	storage_updated.emit()
	
	return true

# Возвращает продукт по ID
func get_item(item_id: String) -> Dictionary:
	if stock.has(item_id):
		return stock[item_id]
	return {}

# Возвращает количество продукта на складе
func get_item_count(item_id: String) -> int:
	if stock.has(item_id):
		return stock[item_id]["count"]
	return 0

# Возвращает качество продукта на складе
func get_item_quality(item_id: String) -> int:
	if stock.has(item_id):
		return stock[item_id]["quality"]
	return 0

# Возвращает список всех продуктов на складе
func get_all_items() -> Dictionary:
	return stock.duplicate()

# Возвращает количество типов продуктов на складе
func get_types_count() -> int:
	return stock.size()

# Возвращает общее количество всех продуктов на складе
func get_total_count() -> int:
	var total = 0
	for item_id in stock:
		total += stock[item_id]["count"]
	return total

# Проверяет, есть ли место для нового продукта
func has_space_for(item_id: String) -> bool:
	# Проверяем место по типам
	if not stock.has(item_id) and stock.size() >= max_types_capacity:
		return false
	
	# Проверяем место по количеству
	if stock.has(item_id):
		return stock[item_id]["count"] < max_item_capacity
	
	return true

# Создает карточку продукта из склада
func create_product_card(item_id: String, card_scene) -> Card:
	if not stock.has(item_id):
		return null
	
	var item_data = stock[item_id]["data"]
	var quality = stock[item_id]["quality"]
	
	# Создаем карточку
	var card = card_scene.instantiate() as Card
	card.set_item(item_data)
	card.set_quality(quality)
	
	# Добавляем метку с количеством, если больше 1
	if stock[item_id]["count"] > 1:
		var count_label = Label.new()
		count_label.name = "CountLabel"
		count_label.text = "x" + str(stock[item_id]["count"])
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		card.add_child(count_label)
	
	return card

# Сортирует продукты по категориям
func get_items_by_category() -> Dictionary:
	var categorized = {}
	
	for item_id in stock:
		var prod_type = stock[item_id]["data"].get("production_type", "other")
		
		if not categorized.has(prod_type):
			categorized[prod_type] = {}
		
		categorized[prod_type][item_id] = stock[item_id]
	
	return categorized

# Сохранение и загрузка
func save_data() -> Dictionary:
	var save_data = {}
	
	for item_id in stock:
		save_data[item_id] = {
			"count": stock[item_id]["count"],
			"quality": stock[item_id]["quality"]
		}
	
	return save_data

func load_data(data: Dictionary) -> void:
	stock.clear()
	
	for item_id in data:
		var item_data = DataService.find_item(item_id)
		if not item_data.is_empty():
			stock[item_id] = {
				"count": data[item_id]["count"],
				"quality": data[item_id]["quality"],
				"data": item_data
			}
	
	storage_updated.emit()
