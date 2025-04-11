class_name ToolInstance
extends Node2D

# Сигналы для взаимодействия с другими системами
signal processing_started(tool_id: String)
signal processing_completed(tool_id: String, product_id: String, quality: int)
signal slot_content_changed(slot_id: String, content_id: String)

# Идентификатор инструмента и экземпляра
@export var tool_id: String
@export var instance_id: String

# Данные инструмента
var tool_data: ToolData
var is_processing: bool = false
var slots: Dictionary = {}  # slot_id -> content_data
var processing_time: float = 0.0
var result_product_id: String = ""
var result_quality: int = 0

# Компоненты UI
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var timer: Timer = $Timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var slots_container: Control = $SlotsContainer

# Ссылки на другие системы
@onready var production_manager: ProductionManager = $"/root/ProductionManager"

# Инициализация инструмента
func _ready() -> void:
	# Генерируем уникальный ID экземпляра, если не задан
	if instance_id.is_empty():
		instance_id = str(get_instance_id())
	
	# Добавляем в группу для удобного поиска
	add_to_group("tool_instances")
	
	# Инициализируем данные инструмента
	initialize_tool_data()
	
	# Настраиваем таймер
	timer.one_shot = true
	timer.connect("timeout", _on_timer_timeout)
	
	# Скрываем прогресс-бар
	progress_bar.visible = false

# Инициализация данных инструмента
func initialize_tool_data() -> void:
	if tool_id.is_empty():
		push_error("ToolInstance: tool_id не указан")
		return
	
	# Получаем данные инструмента
	tool_data = production_manager.get_tool(tool_id)
	if not tool_data:
		push_error("ToolInstance: инструмент с ID " + tool_id + " не найден")
		return
	
	# Инициализируем слоты
	initialize_slots()
	
	# Устанавливаем внешний вид
	update_visual()

# Инициализация слотов инструмента
func initialize_slots() -> void:
	# Очищаем текущие слоты
	slots.clear()
	
	# Удаляем существующие визуальные слоты
	for child in slots_container.get_children():
		child.queue_free()
	
	# Создаем новые слоты согласно конфигурации
	if tool_data:
		for slot_config in tool_data.slots:
			var slot_id = slot_config.get("id", "")
			slots[slot_id] = null
			
			# Создаем визуальный слот
			var slot = preload("res://scenes/production/ToolSlot.tscn").instantiate()
			slot.slot_id = slot_id
			slot.slot_type = slot_config.get("type", "")
			slot.required = slot_config.get("required", true)
			slot.display_name = slot_config.get("display_name", "")
			slot.connect("item_dropped", _on_item_dropped_to_slot)
			slot.connect("item_removed", _on_item_removed_from_slot)
			slots_container.add_child(slot)

# Обновление визуального представления инструмента
func update_visual() -> void:
	# Устанавливаем спрайт
	if tool_data:
		var sprite_path = "res://assets/images/tools/" + tool_data.sprite + ".png"
		if ResourceLoader.exists(sprite_path):
			$Sprite2D.texture = load(sprite_path)
		else:
			# Если спрайт не найден, используем заглушку
			$Sprite2D.texture = preload("res://assets/images/tools/default.png")
	
	# Обновляем отображение слотов
	for slot_id in slots:
		var slot_content = slots[slot_id]
		var slot_node = get_slot_node(slot_id)
		if slot_node:
			slot_node.update_visual(slot_content)

# Получение ноды слота по ID
func get_slot_node(slot_id: String) -> Node:
	for child in slots_container.get_children():
		if child.has_method("get_slot_id") and child.get_slot_id() == slot_id:
			return child
	return null

# Проверка возможности добавления предмета в слот
func can_accept_item(slot_id: String, item_data) -> bool:
	# Проверка наличия слота
	if not slot_id in slots:
		return false
	
	# Проверка занятости слота
	if slots[slot_id] != null:
		return false
	
	# Проверка совместимости типов
	var slot_node = get_slot_node(slot_id)
	if not slot_node:
		return false
	
	var required_type = slot_node.slot_type
	var item_type = ""
	
	if item_data is IngredientData:
		item_type = item_data.type
	elif item_data is ProductData:
		item_type = item_data.type
	
	return required_type == item_type

# Добавление предмета в слот
func add_item_to_slot(slot_id: String, item_data) -> bool:
	if not can_accept_item(slot_id, item_data):
		return false
	
	# Добавляем предмет в слот
	slots[slot_id] = item_data
	
	# Обновляем визуальное отображение
	var slot_node = get_slot_node(slot_id)
	if slot_node:
		slot_node.update_visual(item_data)
	
	# Отправляем сигнал об изменении содержимого слота
	var item_id = ""
	if item_data is IngredientData:
		item_id = item_data.id
	elif item_data is ProductData:
		item_id = item_data.id
	
	emit_signal("slot_content_changed", slot_id, item_id)
	
	return true

# Удаление предмета из слота
func remove_item_from_slot(slot_id: String) -> Variant:
	if not slot_id in slots or slots[slot_id] == null:
		return null
	
	var item = slots[slot_id]
	slots[slot_id] = null
	
	# Обновляем визуальное отображение
	var slot_node = get_slot_node(slot_id)
	if slot_node:
		slot_node.update_visual(null)
	
	# Отправляем сигнал об изменении содержимого слота
	emit_signal("slot_content_changed", slot_id, "")
	
	return item

# Проверка готовности к запуску процесса
func can_start_processing() -> bool:
	if is_processing:
		return false
	
	# Проверяем наличие всех необходимых ингредиентов
	for slot_id in slots:
		var slot_node = get_slot_node(slot_id)
		if slot_node and slot_node.required and slots[slot_id] == null:
			return false
	
	return true

# Поиск подходящего рецепта
func find_matching_recipe() -> String:
	# Собираем ID всех ингредиентов в слотах
	var ingredients = []
	for slot_id in slots:
		var item = slots[slot_id]
		if item != null:
			var item_id = ""
			if item is IngredientData:
				item_id = item.id
			elif item is ProductData:
				item_id = item.id
			
			if not item_id.is_empty():
				ingredients.append(item_id)
	
	# Ищем подходящий рецепт
	for recipe_id in production_manager.available_products:
		var product = production_manager.available_products[recipe_id]
		
		# Проверяем совпадение инструмента
		if product.tool_id != tool_id:
			continue
		
		# Проверяем совпадение ингредиентов
		var recipe_ingredients = product.ingredients
		if recipe_ingredients.size() != ingredients.size():
			continue
		
		# Проверяем, все ли ингредиенты из рецепта присутствуют
		var all_match = true
		for ingredient_id in recipe_ingredients:
			if not ingredient_id in ingredients:
				all_match = false
				break
		
		if all_match:
			return recipe_id
	
	return ""

# Установка данных для обработки
func set_processing_data(time: float, product_id: String, quality: int) -> void:
	processing_time = time
	result_product_id = product_id
	result_quality = quality

# Запуск процесса обработки
func start_processing() -> bool:
	if not can_start_processing():
		return false
	
	# Если рецепт не был явно указан, пытаемся найти его
	if result_product_id.is_empty():
		result_product_id = find_matching_recipe()
		if result_product_id.is_empty():
			push_error("ToolInstance: не найден подходящий рецепт")
			return false
	
	# Устанавливаем время обработки, если не было указано
	if processing_time <= 0:
		processing_time = tool_data.processing_time
	
	# Запускаем таймер
	timer.wait_time = processing_time
	timer.start()
	
	# Показываем и настраиваем прогресс-бар
	progress_bar.visible = true
	progress_bar.max_value = processing_time
	progress_bar.value = 0
	
	# Запускаем анимацию
	if animation_player.has_animation("processing"):
		animation_player.play("processing")
	
	# Устанавливаем флаг обработки
	is_processing = true
	
	# Отправляем сигнал о начале обработки
	emit_signal("processing_started", tool_id)
	
	return true

# Обработка тика для обновления прогресс-бара
func _process(delta: float) -> void:
	if is_processing and timer.time_left > 0:
		progress_bar.value = processing_time - timer.time_left

# Обработчик завершения таймера
func _on_timer_timeout() -> void:
	complete_processing()

# Завершение процесса обработки
func complete_processing() -> void:
	if not is_processing:
		return
	
	# Останавливаем анимацию
	if animation_player.is_playing():
		animation_player.stop()
	
	# Скрываем прогресс-бар
	progress_bar.visible = false
	
	# Сбрасываем флаг обработки
	is_processing = false
	
	# Очищаем слоты
	for slot_id in slots:
		slots[slot_id] = null
		var slot_node = get_slot_node(slot_id)
		if slot_node:
			slot_node.update_visual(null)
	
	# Отправляем сигнал о завершении обработки
	emit_signal("processing_completed", tool_id, result_product_id, result_quality)
	
	# Сбрасываем данные обработки
	result_product_id = ""
	result_quality = 0
	processing_time = 0
	
	# Уведомляем менеджер производства
	production_manager._on_crafting_completed(result_product_id, result_quality)

# Обработчик события перетаскивания предмета в слот
func _on_item_dropped_to_slot(slot_id: String, item_data) -> void:
	add_item_to_slot(slot_id, item_data)

# Обработчик события удаления предмета из слота
func _on_item_removed_from_slot(slot_id: String) -> void:
	remove_item_from_slot(slot_id)

# Получение информации для отображения в UI
func get_info() -> Dictionary:
	var result = {
		"name": tool_data.name,
		"description": tool_data.description,
		"quality": tool_data.quality,
		"is_processing": is_processing,
		"slots": []
	}
	
	# Добавляем информацию о слотах
	for slot_id in slots:
		var slot_node = get_slot_node(slot_id)
		if slot_node:
			result.slots.append({
				"id": slot_id,
				"type": slot_node.slot_type,
				"display_name": slot_node.display_name,
				"required": slot_node.required,
				"content": slots[slot_id] != null
			})
	
	# Если идет обработка, добавляем данные о прогрессе
	if is_processing:
		result["progress"] = {
			"current": progress_bar.value,
			"total": processing_time,
			"time_left": timer.time_left
		}
	
	return result
