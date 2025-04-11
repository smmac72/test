class_name ShopUI
extends Control

# Сигналы
signal product_sold(product_id: String, quality: int, price: int, customer_id: String)
signal customer_left(customer_id: String, satisfied: bool)
signal money_taken_from_cash(amount: int)

# Узлы UI
@onready var counter_panel: Panel = $VBoxContainer/ShopArea/VBoxContainer/CounterPanel
@onready var customer_area: Control = $VBoxContainer/ShopArea/VBoxContainer/CustomerArea
@onready var storage_panel: Panel = $VBoxContainer/ShopArea/VBoxContainer/StoragePanel
@onready var storage_grid: GridContainer = $VBoxContainer/ShopArea/VBoxContainer/StoragePanel/StorageGrid

# Активный клиент
var active_customer = null
var available_products: Dictionary = {}  # id_quality -> {product, price_modifier}
var storage_slots: Array = []

# Ссылки на менеджеры
@onready var production_manager: ProductionManager = $"/root/ProductionManager"
@onready var game_manager: GameManager = $"/root/GameManager"
@onready var customer_manager: CustomerManager = $"/root/CustomerManager"

# Инициализация
func _ready() -> void:
	# Подключаем сигналы
	production_manager.connect("recipe_completed", _on_recipe_completed)
	
	# Инициализируем сетку склада
	initialize_storage_grid()

# Полная инициализация магазина
func initialize() -> void:
	# Загружаем товары из сохранения, если они есть
	load_storage_products()
	
	# Запускаем генерацию клиентов
	customer_manager.start_customer_generation()
	
	# Подключаем сигналы клиентов
	customer_manager.connect("customer_arrived", _on_customer_arrived)

# Инициализация сетки склада
func initialize_storage_grid() -> void:
	# Очищаем текущую сетку
	for child in storage_grid.get_children():
		child.queue_free()
	
	# Создаем новые слоты для склада
	var slot_count = 9  # 3x3 сетка
	storage_slots.clear()
	
	for i in range(slot_count):
		var slot = preload("res://scenes/shop/StorageSlot.tscn").instantiate()
		slot.slot_id = "storage_slot_" + str(i)
		slot.connect("slot_clicked", _on_storage_slot_clicked)
		slot.connect("item_dragged", _on_storage_item_dragged)
		storage_grid.add_child(slot)
		storage_slots.append(slot)

# Загрузка товаров из сохранения
func load_storage_products() -> void:
	# Получаем товары из Production Manager
	var final_products = production_manager.get_products_by_type("samogon", true)
	final_products.append_array(production_manager.get_products_by_type("beer", true))
	final_products.append_array(production_manager.get_products_by_type("wine", true))
	
	# Отображаем товары на складе
	for product in final_products:
		if product.count > 0:
			add_product_to_storage(product)

# Обработчик завершения создания продукта
func _on_recipe_completed(product_id: String, quality: int) -> void:
	# Проверяем, что это конечный продукт
	var product = production_manager.get_product(product_id)
	if product and product.is_final:
		# Добавляем продукт на склад
		add_product_to_storage(product)

# Добавление продукта на склад
func add_product_to_storage(product: ProductData) -> void:
	# Ищем свободный слот
	var target_slot = null
	
	# Сначала ищем слот с таким же продуктом для стакования
	for slot in storage_slots:
		if slot.is_occupied() and slot.product_id == product.id and slot.quality == product.quality:
			# Увеличиваем количество в существующем слоте
			slot.increment_count()
			return
	
	# Если не нашли, ищем пустой слот
	for slot in storage_slots:
		if not slot.is_occupied():
			target_slot = slot
			break
	
	# Если нашли свободный слот, добавляем продукт
	if target_slot:
		target_slot.set_product(product.id, product.name, product.quality, 1)
		
		# Добавляем продукт в список доступных товаров
		var product_key = product.id + "_" + str(product.quality)
		available_products[product_key] = {
			"product": product,
			"price_modifier": 1.0  # стандартная цена
		}
	else:
		# Если нет свободных слотов, показываем уведомление
		show_notification("Склад полон! Освободите место.")

# Обработчик нажатия на слот склада
func _on_storage_slot_clicked(slot) -> void:
	if slot.is_occupied():
		# Показываем информацию о продукте
		show_product_info(slot)

# Показ информации о продукте
func show_product_info(slot) -> void:
	var product_key = slot.product_id + "_" + str(slot.quality)
	if product_key in available_products:
		var product_data = available_products[product_key]
		
		# Создаем и показываем попап
		var popup = preload("res://scenes/ui/ProductInfoPopup.tscn").instantiate()
		popup.setup(product_data["product"], product_data["price_modifier"])
		popup.connect("price_changed", _on_product_price_changed.bind(product_key))
		popup.connect("discard_pressed", _on_product_discard_pressed.bind(slot))
		add_child(popup)
		popup.popup_centered()

# Обработчик изменения цены продукта
func _on_product_price_changed(new_modifier: float, product_key: String) -> void:
	if product_key in available_products:
		available_products[product_key]["price_modifier"] = new_modifier
		
		# Обновляем соответствующий слот
		for slot in storage_slots:
			if slot.is_occupied() and slot.product_id + "_" + str(slot.quality) == product_key:
				slot.update_price_modifier(new_modifier)
				break

# Обработчик удаления продукта
func _on_product_discard_pressed(slot) -> void:
	if slot.is_occupied():
		# Уменьшаем количество в слоте
		if slot.decrement_count():
			# Если слот опустел, удаляем продукт из списка доступных
			var product_key = slot.product_id + "_" + str(slot.quality)
			if product_key in available_products:
				available_products.erase(product_key)

# Обработчик перетаскивания товара из склада
func _on_storage_item_dragged(slot, global_position: Vector2) -> void:
	if not slot.is_occupied() or not active_customer:
		return
	
	# Проверяем, брошен ли товар на клиента
	if _is_position_over_customer(global_position):
		# Пытаемся продать товар клиенту
		sell_product_to_customer(slot.product_id, slot.quality, slot)

# Проверка, находится ли позиция над клиентом
func _is_position_over_customer(global_position: Vector2) -> bool:
	if not active_customer:
		return false
	
	var customer_rect = active_customer.get_global_rect()
	return customer_rect.has_point(global_position)

# Продажа товара клиенту
func sell_product_to_customer(product_id: String, quality: int, slot) -> void:
	if not active_customer:
		return
	
	# Получаем данные о продукте
	var product_key = product_id + "_" + str(quality)
	if not product_key in available_products:
		return
	
	var product_data = available_products[product_key]
	var base_price = product_data["product"].get_current_price()
	var final_price = int(base_price * product_data["price_modifier"])
	
	# Проверяем, примет ли клиент этот товар
	var accepted = customer_manager.offer_product_to_customer(
		active_customer.customer_id, 
		product_id, 
		quality, 
		final_price
	)
	
	if accepted:
		# Обработка успешной продажи
		game_manager.change_money(final_price, "Продажа " + product_data["product"].name)
		
		# Уменьшаем количество в слоте
		if slot.decrement_count():
			# Если слот опустел, удаляем продукт из списка доступных
			available_products.erase(product_key)
		
		# Отправляем сигнал о продаже
		emit_signal("product_sold", product_id, quality, final_price, active_customer.customer_id)
		
		# Клиент уходит довольный
		_customer_leave(true)
		
		# Показываем уведомление
		show_notification("Продажа успешна! +" + str(final_price) + "₽")
	else:
		# Клиент отказался
		show_notification("Клиент отказался от покупки.")

# Обработчик прихода клиента
func _on_customer_arrived(customer_data: Dictionary) -> void:
	# Если уже есть активный клиент, ставим нового в очередь
	if active_customer:
		customer_manager.add_to_queue(customer_data)
		return
	
	# Создаем экземпляр клиента
	var customer = preload("res://scenes/shop/Customer.tscn").instantiate()
	customer.setup(customer_data)
	customer.connect("customer_clicked", _on_customer_clicked)
	customer.connect("customer_leave_requested", _on_customer_leave_requested)
	customer_area.add_child(customer)
	
	# Запоминаем активного клиента
	active_customer = customer
	
	# Показываем уведомление
	show_notification("Прибыл новый клиент!")

# Обработчик нажатия на клиента
func _on_customer_clicked(customer) -> void:
	# Показываем диалог с клиентом
	var dialog = preload("res://scenes/ui/CustomerDialog.tscn").instantiate()
	dialog.setup(customer.customer_data)
	add_child(dialog)
	dialog.popup_centered()

# Обработчик запроса клиента на уход
func _on_customer_leave_requested(customer, satisfied: bool) -> void:
	_customer_leave(satisfied)

# Уход клиента
func _customer_leave(satisfied: bool) -> void:
	if not active_customer:
		return
	
	# Отправляем сигнал об уходе клиента
	emit_signal("customer_left", active_customer.customer_id, satisfied)
	
	# Удаляем клиента
	active_customer.queue_free()
	active_customer = null
	
	# Проверяем очередь
	var next_customer = customer_manager.get_next_from_queue()
	if next_customer:
		# Создаем следующего клиента
		_on_customer_arrived(next_customer)

# Обработчик нажатия на кассу
func _on_cash_register_clicked() -> void:
	# Показываем меню кассы
	var cash_menu = preload("res://scenes/ui/CashRegisterMenu.tscn").instantiate()
	cash_menu.connect("money_taken", _on_money_taken_from_cash)
	add_child(cash_menu)
	cash_menu.popup_centered()

# Обработчик взятия денег из кассы
func _on_money_taken_from_cash(amount: int) -> void:
	# Отправляем сигнал о взятии денег
	emit_signal("money_taken_from_cash", amount)

# Показ временного уведомления
func show_notification(text: String) -> void:
	var notification = preload("res://scenes/ui/Notification.tscn").instantiate()
	notification.setup(text)
	add_child(notification)
	
	# Автоматическое исчезновение через 3 секунды
	var timer = get_tree().create_timer(3.0)
	timer.connect("timeout", notification.queue_free)
