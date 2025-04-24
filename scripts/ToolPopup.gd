extends Panel
class_name ToolPopup

var tool_def: Dictionary          # из tools.json
var slots: Array[Slot] = []       # Массив слотов
var progress_bar: ProgressBar
var is_running: bool = false
var upgrade_level: int = 0
var processing_duration: float = 1.0
var processing_elapsed: float = 0.0


signal finished(product: Dictionary)
signal processing_started
signal processing_update(progress)

@onready var grid: GridContainer = $Grid
@onready var start_btn: Button = $BtnStart
#@onready var timer: Timer = $Timer
@onready var slot_template: Panel = $Grid/SlotTemplate
@onready var close_btn: Button = $CloseButton
@onready var popup_sound: AudioStreamPlayer = $InstrumentCardClosed
@onready var craft_between_sound: AudioStreamPlayer = $CraftSuccessBetween
@onready var craft_botle_sound: AudioStreamPlayer = $CraftBottleSuccess
@onready var craft_faild_sound: AudioStreamPlayer = $CraftFailed
func _is_running () ->bool:
	return is_running

func _ready():
	popup_sound.bus ="&Sfx"
	craft_between_sound.bus="&Sfx"
	craft_botle_sound.bus="&Sfx"
	craft_faild_sound.bus="&Sfx"
	if tool_def.has("name"):
		# Добавляем заголовок
		$Title.text=tool_def.get("name", "Инструмент")
		
		# Добавляем описание
		$Description.text=tool_def.get("description", "")
	
	# Создаем индикатор прогресса
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(420, 20)
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.visible = false
	add_child(progress_bar)
	progress_bar.position = Vector2(10, size.y - 150)
	
	# Подключаем сигналы
	start_btn.pressed.connect(_on_start)
	close_btn.pressed.connect(close_popup)
	#timer.timeout.connect(_on_timer_update)
func close_popup ()->void:
	if (not(is_running)):
		await get_tree().create_timer(0.12).timeout
		popup_sound.play()
		await get_tree().create_timer(0.2).timeout
		queue_free()
		

func setup(tool_data: Dictionary, current_level: int = 0) -> void:
	tool_def = tool_data
	upgrade_level = current_level
	_build_slots()
	_ready()

func _build_slots() -> void:
	# Очищаем существующие слоты
	if (grid != null):
		for child in grid.get_children():
			if child != slot_template:
				child.queue_free()

		slots.clear()

		# Создаем новые слоты согласно tool_def
		if tool_def.has("slots"):
			for slot_conf in tool_def["slots"]:
				var slot := slot_template.duplicate() as Slot
				slot.visible = true
				slot.accepted_type = slot_conf["type"]
				slot.required = slot_conf["required"]
				slot.display_name = slot_conf.get("display_name", slot_conf["type"])
				grid.add_child(slot)
				slots.append(slot)
				
				# Подключаем сигналы слота
				slot.card_placed.connect(_check_can_start)
				slot.card_removed.connect(_check_can_start)

func _on_start() -> void:
	if is_running or not _all_required():
		return
	
	is_running = true
	start_btn.disabled = true
	_lock_slots()
	
	# Установка времени с учетом уровня
	var base_time = tool_def["processing_time"]
	processing_duration = base_time * (1.0 - 0.05 * upgrade_level)
	processing_elapsed = 0.0
	
	# Подготовка прогресс-бара
	progress_bar.visible = true
	progress_bar.value = 0
	
	set_process(true)
	processing_started.emit()

func _process(delta: float) -> void:
	if not is_running:
		return
	
	processing_elapsed += delta
	var ratio = clamp(processing_elapsed / processing_duration, 0, 1)
	progress_bar.value = ratio * 100
	processing_update.emit(progress_bar.value)
	
	if ratio >= 1.0:
		is_running = false
		set_process(false)
		_on_done()


func _on_timer_update() -> void:
	# Обновляем прогресс-бар
	progress_bar.value += 10
	processing_update.emit(progress_bar.value)
	
	if progress_bar.value >= 100:
		# Завершаем обработку
		_on_done()
	#else:
		# Продолжаем отсчет
		#timer.start()

func _lock_slots() -> void:
	for slot in slots:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _all_required() -> bool:
	for slot in slots:
		if slot.required and slot.contained_card == null:
			return false
	return true

func _check_can_start(_card = null) -> void:
	start_btn.disabled = not _all_required() or is_running

func _on_done() -> void:
	# Создаем продукт на основе рецепта и ингредиентов
	var product := _produce()
	
	# Показываем результат и завершаем
	_show_result(product)
	
	# Уведомляем о завершении и закрываем попап
	finished.emit(product)
	
	# Задержка перед закрытием, чтобы пользователь увидел результат
	await get_tree().create_timer(1.0).timeout
	queue_free()


func _produce() -> Dictionary:
	# Собираем информацию о ингредиентах
	var ingredient_ids: Array[String] = []
	var ingredient_qualities: Array[int] = []
	
	for slot in slots:
		if slot.contained_card:
			ingredient_ids.append(slot.contained_card.item_data["id"])
			ingredient_qualities.append(slot.contained_card.get_quality())
	
	# Ищем подходящий рецепт в списке продуктов
	var matching_recipe: Dictionary = {}
	
	# Сначала проверяем финальные продукты
	for recipe in DataService.recipes.get("final_products", []):
		if recipe["tool_id"] == tool_def["id"] and _ingredients_match(recipe["ingredients"], ingredient_ids):
			matching_recipe = recipe.duplicate()
			break
	
	# Если не нашли в финальных, проверяем в промежуточных
	if matching_recipe.is_empty():
		for recipe in DataService.recipes.get("intermediate_products", []):
			if recipe["tool_id"] == tool_def["id"] and _ingredients_match(recipe["ingredients"], ingredient_ids):
				matching_recipe = recipe.duplicate()
				break
	
	# Если нашли подходящий рецепт, вычисляем качество
	if not matching_recipe.is_empty():
		var quality_level = _calculate_quality(ingredient_qualities)
		matching_recipe["quality"] = quality_level
	
	return matching_recipe

func _ingredients_match(needed: Array, provided: Array) -> bool:
	if needed.size() > provided.size():
		return false
	
	# Проверяем, что все необходимые ингредиенты присутствуют
	for item in needed:
		if item not in provided:
			return false
	
	return true

func _calculate_quality(qualities: Array[int]) -> int:
	if qualities.is_empty():
		return 0
	
	var total_quality = 0
	for q in qualities:
		total_quality += q
	
	# Учитываем уровень улучшения инструмента
	total_quality += upgrade_level
	
	# Среднее значение с округлением
	var avg_quality = total_quality / (qualities.size() + 1)  # +1 для учета инструмента
	
	# Ограничиваем качество от 0 до 3
	return clampi(roundi(avg_quality), 0, 3)

func _show_result(product: Dictionary) -> void:
	if product.is_empty():
		# Ничего не получилось
		craft_faild_sound.play()
		var fail_label = Label.new()
		fail_label.text = "Ошибка рецепта!"
		fail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fail_label.add_theme_font_size_override("font_size", 16)
		fail_label.add_theme_color_override("font_color", Color(1, 0, 0))
		add_child(fail_label)
		fail_label.position = Vector2(size.x/2 - fail_label.size.x/2, size.y - 100)
	else:
		if (product["type"] == "final_product"):
			craft_botle_sound.play()
		else:
			craft_between_sound.play()
		# Показываем результат
		var result_label = Label.new()
		result_label.text = "Создано: %s (%s⭐)" % [product["name"], product["quality"]]
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 16)
		result_label.add_theme_color_override("font_color", Color(0, 1, 0))
		add_child(result_label)
		result_label.position = Vector2(size.x/2 - result_label.size.x/2, size.y )
