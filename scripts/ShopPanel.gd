extends Panel
class_name ShopPanel

# UI компоненты
@onready var background = $Background
@onready var window = $Window
@onready var sill = $Sill
@onready var bottle_shelf_container = $BottleShelf
@onready var orders_scroll = $OrdersPanel/OrdersScroll
@onready var orders_vbox = $OrdersPanel/OrdersScroll/OrdersVBox
@onready var no_orders_label = $OrdersPanel/NoOrdersLabel
@onready var radio = $Sill/Radio
@onready var btn_reject = $OrdersPanel/RejectButton
# Сцены и ресурсы
var order_card_scene = preload("res://scenes/OrderCard.tscn")
var card_scene = preload("res://scenes/widgets/Card.tscn")

# Менеджеры и сервисы
@onready var order_manager = OrderManager
@onready var time_manager = TimeManager
@onready var radio_controller = RadioController
@onready var sound_reject:Array =  [$CancelledOrder,$CancelledOrder3,$CancelledOrder2]

# Текущее активное состояние
var current_order_card = null
var shelf_products = []
var can_receive_product = true

# Настройки
var max_shelf_capacity = 12  # Максимальное количество товаров на полке
var card_size = Vector2(78, 128)  # Размер карточек на полке

# Сигналы
signal product_sold(product_id, quality, price)
signal order_fulfilled(order_data, price)
signal order_rejected(order_data)

func _ready() -> void:
	# Настраиваем полку для продуктов, если она типа HBoxContainer
	if bottle_shelf_container:
		bottle_shelf_container.add_theme_constant_override("separation", 15)  # Добавляем расстояние между элементами
	
	# Добавляем клиентскую зону, если её нет
	if not has_node("ClientArea"):
		var client_area = Control.new()
		client_area.name = "ClientArea"
		add_child(client_area)
		client_area.position = Vector2(window.size.x * 0.5, window.position.y + window.size.y * 0.5)
		
		var client_sprite = Sprite2D.new()
		client_sprite.name = "ClientSprite"
		client_sprite.visible = false
		client_area.add_child(client_sprite)
		
		var client_text = Label.new()
		client_text.name = "ClientText"
		client_text.visible = false
		client_text.position = Vector2(-75, 50)
		client_text.size = Vector2(150, 25)
		client_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		client_area.add_child(client_text)
	
	# Добавляем кнопку отклонения заказа
	btn_reject.pressed.connect(_on_reject_button_pressed)
	
	# Подключаем сигналы
	order_manager.new_order.connect(_on_new_order)
	order_manager.order_completed.connect(_on_order_completed)
	order_manager.order_rejected.connect(_on_order_rejected)
	
	# Настраиваем радиоx
	radio.gui_input.connect(_on_radio_input)
	
	# Обновляем начальное состояние UI
	_update_shelf_ui()
	_update_orders_ui()

func _on_new_order(order: Dictionary) -> void:
	# Очищаем предыдущие заказы
	for child in orders_vbox.get_children():
		child.queue_free()
	
	# Создаем новую карточку заказа
	var card = order_card_scene.instantiate() as OrderCard
	card.call_deferred("set_order", order)
	orders_vbox.add_child(card)
	
	# Сохраняем ссылку на текущий заказ
	current_order_card = card
	
	# Подключаем сигнал нажатия на заказ
	card.order_clicked.connect(_on_order_clicked)
	
	# Показываем клиента
	_show_client(order["client"])
	
	# Обновляем UI
	_update_orders_ui()
	
	# Анимация появления
	card.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(card, "modulate:a", 1.0, 0.4)

func _on_order_completed(order: Dictionary, price: int) -> void:
	# Уведомляем о выполнении заказа
	order_fulfilled.emit(order, price)
	
	# Очищаем текущий заказ
	if current_order_card:
		current_order_card.queue_free()
		current_order_card = null
	
	# Скрываем клиента
	_hide_client()
	
	# Обновляем UI
	_update_orders_ui()
	
	# Показываем сообщение об успешной продаже
	PopupManager.show_message("Продано за " + str(price) + "₽!", 2.0, Color(0, 1, 0))

func _on_order_rejected(order: Dictionary) -> void:
	# Уведомляем об отклонении заказа
	order_rejected.emit(order)
	
	# Очищаем текущий заказ
	if current_order_card:
		current_order_card.queue_free()
		current_order_card = null
	
	# Скрываем клиента
	_hide_client()
	
	# Обновляем UI
	_update_orders_ui()
	
	# Показываем сообщение об отклонении
	PopupManager.show_message("Заказ отклонен", 2.0, Color(1, 0.5, 0.5))

func _on_reject_button_pressed() -> void:
	# Отклоняем текущий заказ
	sound_reject.pick_random().play()
	await get_tree().create_timer(1.5).timeout
	order_manager.reject_order()

func _on_order_clicked(order_card: OrderCard) -> void:
	# Проверяем наличие продуктов на полке
	if shelf_products.size() == 0:
		# Показываем сообщение, что нет продуктов
		PopupManager.show_message("Нет продуктов для продажи!", 2.0, Color(1, 0.5, 0.5))
		return
	
	# Проверяем каждый продукт на полке
	for product in shelf_products:
		# Если продукт подходит для заказа
		if order_manager.can_fulfill_with_product(product):
			# Выполняем заказ
			_fulfill_order(product)
			return
	
	# Если не нашли подходящий продукт
	PopupManager.show_message("Нет подходящего продукта для заказа!", 2.0, Color(1, 0.5, 0.5))

func _fulfill_order(product_card: Card) -> void:
	# Рассчитываем цену
	var price = order_manager.calculate_price(product_card)
	
	# Уведомляем менеджер заказов о выполнении
	product_sold.emit(product_card.item_data.get("id", ""), product_card.get_quality(), price)
	
	# Удаляем продукт с полки
	_remove_product_from_shelf(product_card)
	
	# Отмечаем заказ как выполненный
	order_manager.complete_order(price)
	
	# Показываем эффект успешной продажи
	_show_sale_effect(price)

func _show_client(client: Dictionary) -> void:
	var client_area = get_node("ClientArea")
	var client_sprite = client_area.get_node("ClientSprite")
	var client_text = client_area.get_node("ClientText")
	
	# Загружаем изображение клиента
	var visual_key = client.get("visual", "client_placeholder")
	var texture_path = "res://art/clients/%s.png" % visual_key
	
	if ResourceLoader.exists(texture_path):
		client_sprite.texture = load(texture_path)
	else:
		# Используем заглушку
		client_sprite.texture = load("res://art/client_placeholder.png")
	
	# Показываем спрайт и текст
	client_sprite.visible = true
	client_text.visible = true
	client_text.text = client.get("name", "Клиент")
	
	# Анимация появления
	client_sprite.modulate.a = 0
	client_text.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(client_sprite, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(client_text, "modulate:a", 1.0, 0.5)

func _hide_client() -> void:
	var client_area = get_node("ClientArea")
	var client_sprite = client_area.get_node("ClientSprite")
	var client_text = client_area.get_node("ClientText")
	
	# Анимация исчезновения
	if client_sprite.visible:
		var tween = create_tween()
		tween.tween_property(client_sprite, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(client_text, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			client_sprite.visible = false
			client_text.visible = false
		)

func _on_radio_input(event) -> void:
	# Обработка клика по радио
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		radio_controller.next_station()
		
		# Анимация поворота радио
		var tween = create_tween()
		tween.tween_property(radio, "rotation", radio.rotation + 0.1, 0.1)
		tween.tween_property(radio, "rotation", radio.rotation, 0.1)

func _update_orders_ui() -> void:
	# Показываем или скрываем метку "нет заказов"
	var no_orders = current_order_card == null
	if has_node("OrdersPanel/NoOrdersLabel"):
		get_node("OrdersPanel/NoOrdersLabel").visible = no_orders

func _update_shelf_ui() -> void:
	# Показываем или скрываем метку "нет продуктов"
	var no_products = shelf_products.size() == 0
	if has_node("BottleShelf/NoProductsLabel"):
		get_node("BottleShelf/NoProductsLabel").visible = no_products

func add_product_to_shelf(product_card: Card) -> bool:
	# Проверяем, не заполнена ли полка
	if shelf_products.size() >= max_shelf_capacity:
		return false
	
	# Проверяем, является ли продукт конечным продуктом
	var product_type = product_card.item_data.get("type", "")
	if product_type != "final_product":
		return false
	
	# Удаляем из текущего родителя
	if product_card.get_parent():
		product_card.get_parent().remove_child(product_card)
	
	# Создаем копию карточки для полки
	var shelf_card = card_scene.instantiate() as Card
	shelf_card.set_item(product_card.item_data)
	shelf_card.set_quality(product_card.get_quality())
	
	# Настраиваем размер
	shelf_card.custom_minimum_size = card_size
	
	# Добавляем на полку
	bottle_shelf_container.add_child(shelf_card)
	shelf_products.append(shelf_card)
	
	# Уменьшаем размер шрифта для лучшей читаемости
	if shelf_card.has_node("Label"):
		shelf_card.get_node("Label").add_theme_font_size_override("font_size", 12)
	
	# Настраиваем интерактивность
	shelf_card.gui_input.connect(_on_shelf_product_input.bind(shelf_card))
	
	# Обновляем UI
	_update_shelf_ui()
	
	return true

func _remove_product_from_shelf(product_card: Card) -> void:
	# Удаляем продукт из списка
	shelf_products.erase(product_card)
	
	# Удаляем карточку
	product_card.queue_free()
	
	# Обновляем UI
	_update_shelf_ui()

func _on_shelf_product_input(event: InputEvent, product_card: Card) -> void:
	# Обработка нажатия на продукт на полке
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Если есть активный заказ, пробуем выполнить его напрямую
		if current_order_card and order_manager.can_fulfill_with_product(product_card):
			_fulfill_order(product_card)
			return
		
		# Иначе, начинаем стандартное перетаскивание
		product_card._get_drag_data(Vector2.ZERO)

# Функции для обработки перетаскивания из производственной панели
func _can_drop_data(_pos, data) -> bool:
	# Принимаем только карточки продуктов
	if data is Card and can_receive_product:
		var product_type = data.item_data.get("type", "")
		# Принимаем только конечные продукты и не превышаем лимит
		var res = bool (product_type == "final_product" and shelf_products.size() < max_shelf_capacity)
		return res
	return false

func _drop_data(_pos, data) -> void:
	# Добавляем продукт на полку
	if data is Card:
		add_product_to_shelf(data)

func _show_sale_effect(amount: int) -> void:
	# Создаем метку с суммой продажи
	var label = Label.new()
	label.text = "+%d₽" % amount
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0, 1, 0))
	add_child(label)
	
	# Позиционируем над клиентом
	var client_area = get_node("ClientArea")
	var client_sprite = client_area.get_node("ClientSprite")
	label.global_position = client_sprite.global_position - Vector2(0, 50)
	
	# Анимируем и удаляем
	var tween = create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 50, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)


@onready var radio_b = $Sill/Radio
@onready var radio_b_controller = RadioController

func _on_radio_b_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		radio_controller.next_station()

		var tween = create_tween()
		tween.tween_property(radio, "rotation", radio.rotation + 0.1, 0.1)
		tween.tween_property(radio, "rotation", radio.rotation, 0.1)
