class_name StorageSlot
extends Control

# Сигналы
signal slot_clicked(slot)
signal item_dragged(slot, global_position)

# Свойства
@export var slot_id: String = ""

# Состояние слота
var product_id: String = ""
var product_name: String = ""
var quality: int = 0
var count: int = 0
var price_modifier: float = 1.0

# Компоненты
@onready var background: Panel = $Background
@onready var product_icon: TextureRect = $ProductIcon
@onready var quality_stars: HBoxContainer = $QualityStars
@onready var count_label: Label = $CountLabel
@onready var price_icon: TextureRect = $PriceIcon
@onready var price_label: Label = $PriceLabel

# Состояние перетаскивания
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Настройка слота
	update_visual()
	
	# Подключение сигналов
	connect("gui_input", _on_gui_input)

# Проверка, занят ли слот
func is_occupied() -> bool:
	return count > 0

# Установка продукта в слот
func set_product(id: String, name: String, prod_quality: int, prod_count: int, price_mod: float = 1.0) -> void:
	product_id = id
	product_name = name
	quality = prod_quality
	count = prod_count
	price_modifier = price_mod
	
	update_visual()

# Обновление визуального представления
func update_visual() -> void:
	if count <= 0:
		# Пустой слот
		product_icon.visible = false
		quality_stars.visible = false
		count_label.visible = false
		price_icon.visible = false
		price_label.visible = false
		return
	
	# Заполненный слот
	product_icon.visible = true
	quality_stars.visible = true
	count_label.visible = true
	price_icon.visible = true
	price_label.visible = true
	
	# Устанавливаем иконку продукта
	var sprite_path = "res://assets/images/products/" + product_id + ".png"
	if ResourceLoader.exists(sprite_path):
		product_icon.texture = load(sprite_path)
	else:
		product_icon.texture = preload("res://assets/images/products/default.png")
	
	# Устанавливаем звезды качества
	for i in range(quality_stars.get_child_count()):
		var star = quality_stars.get_child(i)
		star.visible = i < quality
	
	# Устанавливаем количество
	count_label.text = str(count)
	
	# Устанавливаем цену с учетом модификатора
	var production_manager = $"/root/ProductionManager"
	var product = production_manager.get_product(product_id)
	if product and quality < product.sell_prices.size():
		var base_price = product.sell_prices[quality]
		var final_price = int(base_price * price_modifier)
		price_label.text = str(final_price) + "₽"
	else:
		price_label.text = "??₽"

# Увеличение количества
func increment_count(amount: int = 1) -> void:
	count += amount
	update_visual()

# Уменьшение количества
func decrement_count(amount: int = 1) -> bool:
	count -= amount
	if count <= 0:
		count = 0
		update_visual()
		return true  # Слот опустел
	
	update_visual()
	return false

# Обновление модификатора цены
func update_price_modifier(new_modifier: float) -> void:
	price_modifier = new_modifier
	update_visual()

# Обработчик ввода
func _on_gui_input(event: InputEvent) -> void:
	if not is_occupied():
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Левый клик для начала перетаскивания
				start_drag(event.global_position)
			else:
				# Конец перетаскивания
				end_drag()
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Правый клик для информации
			emit_signal("slot_clicked", self)

# Процесс для перетаскивания
func _process(delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() - drag_offset

# Начало перетаскивания
func start_drag(mouse_position: Vector2) -> void:
	if dragging or not is_occupied():
		return
	
	dragging = true
	start_position = global_position
	drag_offset = mouse_position - global_position
	z_index = 100  # Поднимаем над другими элементами
	
	# Создаем копию продукта для перетаскивания
	var drag_icon = TextureRect.new()
	drag_icon.texture = product_icon.texture
	drag_icon.expand = true
	drag_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drag_icon.size = Vector2(64, 64)
	add_child(drag_icon)
	
	get_tree().call_group("drag_receiver", "on_drag_started", self)

# Конец перетаскивания
func end_drag() -> void:
	if not dragging:
		return
	
	dragging = false
	z_index = 0
	
	# Удаляем все копии, созданные для перетаскивания
	for child in get_children():
		if child != background and child != product_icon and child != quality_stars and child != count_label and child != price_icon and child != price_label:
			child.queue_free()
	
	# Отправляем сигнал перетаскивания
	emit_signal("item_dragged", self, get_global_mouse_position())
	
	# Возвращаем слот на место
	position = start_position
	
	get_tree().call_group("drag_receiver", "on_drag_ended", self)

# Возврат в исходное положение
func return_to_original() -> void:
	if dragging:
		end_drag()
	else:
		position = start_position
