extends Panel
class_name ProductionManager

# Компоненты производственной панели
@onready var ing_row: HBoxContainer = $IngredientRow
@onready var grid: GridContainer = $WorkGrid
@onready var slot_template: Panel = $WorkGrid/SlotTemplate
@onready var tool_row: HBoxContainer = $VBoxContainer/ToolRow
@onready var bnt_moonshine: Button = $HBoxContainer/ButtonMoonshine
@onready var bnt_beer: Button = $HBoxContainer/ButtonBeer
@onready var bnt_wine: Button = $HBoxContainer/ButtonWine

@onready var bnt_moonshine_ingredient: Button = $HBoxContainer2/ButtonMoonshine
@onready var bnt_beer_ingredient: Button = $HBoxContainer2/ButtonBeer
@onready var bnt_wine_ingredient: Button = $HBoxContainer2/ButtonWine
@onready var popup_sound: AudioStreamPlayer = $InstrumentCardOpen



# Предзагрузка сцен
var card_scene = preload("res://scenes/widgets/Card.tscn")
var tool_popup_scene = preload("res://scenes/widgets/ToolPopup.tscn")

# Массивы для отслеживания объектов
var grid_slots: Array[Slot] = []
var ingredient_cards: Array[Card] = []
var tool_cards: Array[Card] = []
var active_popups: Array = []
var warehouse = {}  # Хранилище готовых продуктов: id -> {card, count}
var popupTools: ToolPopup=null
# Настройки размещения
var ingredient_spacing: int = 10   # Увеличенное расстояние между ингредиентами
var card_size: Vector2 = Vector2(78, 128)  # Увеличенный размер карточек
var slot_size: Vector2 = Vector2(78, 128)  # Увеличенный размер слотов
var grid_spacing: int = 5  # Увеличенное расстояние между слотами сетки
var tool_spacing: int = 80  # Увеличенное расстояние между инструментами
var mode_card_tool: String = "samogon"
var mode_card_ingredient: String = "samogon"
# Сигналы
signal product_created(product_data)


func _ready() -> void:
	popup_sound.bus = "&Sfx"
	# Настраиваем размер контейнеров на всю доступную ширину
	ing_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tool_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Настраиваем контейнеры для правильного размещения
	ing_row.add_theme_constant_override("separation", ingredient_spacing)
	grid.add_theme_constant_override("h_separation", grid_spacing)
	grid.add_theme_constant_override("v_separation", grid_spacing)
	tool_row.add_theme_constant_override("separation", tool_spacing)
	
	# Устанавливаем выравнивание для более равномерного распределения
	ing_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tool_row.alignment = BoxContainer.ALIGNMENT_CENTER
	
	_initialize_grid()
	_initialize_ingredients()
	_initialize_tools()
	bnt_wine.pressed.connect(wine_tool_card)
	bnt_beer.pressed.connect(beer_tool_card)
	bnt_moonshine.pressed.connect(moonshine_tool_card)
	bnt_wine_ingredient.pressed.connect(wine_ingredients_card)
	bnt_beer_ingredient.pressed.connect(beer_ingredients_card)
	bnt_moonshine_ingredient.pressed.connect(moonshine_ingredients_card)
	#bnt_moonshine_ingredient.button_pressed = true
	# Подписываемся на обновления DataService
	DataService.content_updated.connect(_on_content_updated)
	
func _initialize_grid() -> void:
	# Удаляем существующие слоты
	for child in grid.get_children():
		if child != slot_template:
			child.queue_free()
	
	grid_slots.clear()
	
	# Получаем размер сетки из текущего уровня гаража
	var garage_level = UpgradeManager.current_levels.get("garage", 1)
	var grid_size = _get_garage_grid_size(garage_level)
	
	grid.columns = grid_size.x
	
	# Создаем слоты
	for i in range(grid_size.x * grid_size.y):
		var slot = slot_template.duplicate()
		slot.visible = true
		slot.custom_minimum_size = slot_size
		slot.accepted_type = ""  # Принимаем любой тип
		slot.required = false
		
		# Добавляем стиль для лучшей видимости
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.2, 0.1, 0.5)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.3, 0.1)
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_right = 5
		style.corner_radius_bottom_left = 5
		slot.add_theme_stylebox_override("panel", style)
		
		grid.add_child(slot)
		grid_slots.append(slot)

func _get_garage_grid_size(level: int) -> Vector2i:
	# Получаем размер сетки из данных улучшения гаража
	var garage_upgrades = DataService.upgrades.get("garage", [])
	for upgrade in garage_upgrades:
		if upgrade.get("level", 0) == level:
			var size_data = upgrade.get("grid_size", {"width": 4, "height": 4})
			return Vector2i(size_data.get("width", 4), size_data.get("height", 4))
	
	# По умолчанию, если не найдено
	return Vector2i(4, 4)

func _initialize_ingredients() -> void:
	# Очищаем существующие ингредиенты
	for child in ing_row.get_children():
		child.queue_free()
	
	ingredient_cards.clear()
	
	# Создаем карточки для доступных ингредиентов
	for ing_id in DataService.visible_ingredients:
		var card = _create_ingredient_card(ing_id)
		if card:
			ing_row.add_child(card)
			card.custom_minimum_size = card_size
			
			# Добавляем расширение для занятия большего пространства
			var container = MarginContainer.new()
			container.add_child(card)
			container.add_theme_constant_override("margin_left", 5)
			container.add_theme_constant_override("margin_right", 5)
			
			ing_row.add_child(container)
			ingredient_cards.append(card)

func _initialize_tools() -> void:
	# Очищаем существующие инструменты
	for child in tool_row.get_children():
		child.queue_free()
	
	tool_cards.clear()

	# Создаем карточки для доступных инструментов
	for tool_id in DataService.visible_tools:
		var card = _create_tool_card(tool_id)
		if card:
			card.custom_minimum_size = card_size
			
			# Добавляем расширение для занятия большего пространства
			var container = MarginContainer.new()
			container.add_child(card)
			container.add_theme_constant_override("margin_left", 5)
			container.add_theme_constant_override("margin_right", 5)
			
			tool_row.add_child(container)
			tool_cards.append(card)

func _create_ingredient_card(ing_id: String) -> Card:
	# Находим данные ингредиента
	var item_data = null
	
	# Ищем в разных категориях ингредиентов
	for category in ["common", mode_card_ingredient]:
		if DataService.ingredients.has(category):
			for item in DataService.ingredients[category]:
				if item.get("id", "") == ing_id:
					item_data = item
					break
		if item_data:
			break
	
	if not item_data:
		return null
	
	# Создаем карточку
	var card = card_scene.instantiate()
	card.set_item(item_data)
	
	# Устанавливаем начальное качество (может быть изменено позже)
	card.set_quality(0)
	
	# Создаем всплывающее описание
	var popup = Label.new()
	popup.text = item_data.get("description", "")
	popup.visible = false
	popup.name = "DescPopup"
	popup.autowrap_mode = TextServer.AUTOWRAP_WORD
	popup.custom_minimum_size = Vector2(150, 0)
	popup.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Создаем стиль для фона попапа
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	popup.add_theme_stylebox_override("normal", style)

	card.add_child(popup)
	
	
	# Добавляем метку для отображения качества
	var quality_label = Label.new()
	quality_label.name = "Quality"
	quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quality_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quality_label.add_theme_font_size_override("font_size", 14)  # Увеличенный шрифт
	card.add_child(quality_label)
	
	# Увеличиваем размер шрифта названия для лучшей читаемости
	if card.has_node("Label"):
		card.get_node("Label").add_theme_font_size_override("font_size", 14)
	
	# Делаем карточку дублируемой при перетаскивании
	card.gui_input.connect(_on_card_input.bind(card))
	
	return card

func _create_tool_card(tool_id: String) -> Card:
	# Находим данные инструмента
	var tool_data = null
	
	# Ищем в разных категориях инструментов
	var category = mode_card_tool
	if DataService.tools.has(category):
		for item in DataService.tools[category]:
			if item.get("id", "") == tool_id:
				tool_data = item
				break
		
	
	if not tool_data:
		return null
	
	# Создаем карточку
	var card = card_scene.instantiate()
	card.set_item({
		"id": tool_id,
		"name": tool_data.get("name", tool_id),
		"sprite": tool_data.get("sprite", "tool_placeholder"),
		"type": "tool"
	})
	
	# Добавляем текст с уровнем улучшения
	var upgrade_level = UpgradeManager.get_tool_level(tool_id)
	var upgrade_label = Label.new()
	upgrade_label.name = "UpgradeLevel"
	upgrade_label.text = "Ур. " + str(upgrade_level)
	upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	upgrade_label.position += Vector2(5, 5)
	upgrade_label.add_theme_font_size_override("font_size", 14)  # Увеличенный шрифт
	upgrade_label.add_theme_color_override("font_color", Color(0, 0, 0))
	card.add_child(upgrade_label)
	
	# Создаем всплывающее описание
	var popup = Label.new()
	popup.text = tool_data.get("description", "")
	popup.visible = false
	popup.name = "DescPopup"
	popup.autowrap_mode = TextServer.AUTOWRAP_WORD
	popup.custom_minimum_size = Vector2(150, 0)
	popup.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Создаем стиль для фона попапа
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	popup.add_theme_stylebox_override("normal", style)
	
	card.add_child(popup)
	
	# Увеличиваем размер шрифта названия для лучшей читаемости
	if card.has_node("Label"):
		card.get_node("Label").add_theme_font_size_override("font_size", 14)
	
	# Для инструментов используем нажатие мышью для открытия попапа
	card.gui_input.connect(_on_tool_card_input.bind(card, tool_data))
	
	return card

func wine_tool_card()-> void:
	mode_card_tool = "wine"
	_initialize_tools()

func beer_tool_card()-> void:
	mode_card_tool = "beer"
	_initialize_tools()

func moonshine_tool_card()-> void:
	mode_card_tool = "samogon"
	_initialize_tools()

func wine_ingredients_card()-> void:
	mode_card_ingredient = "wine"
	_initialize_ingredients()

func beer_ingredients_card()-> void:
	mode_card_ingredient = "beer"
	_initialize_ingredients()

func moonshine_ingredients_card()-> void:
	mode_card_ingredient = "samogon"
	_initialize_ingredients()

func _on_card_input(event: InputEvent, card: Card) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var parent = card.get_parent() == ing_row
		var grandparent = card.get_parent().get_parent() == ing_row
		if parent or grandparent:
			card.is_template_card = true  # помечаем, что карточка — шаблон

func _on_tool_card_input(event: InputEvent, card: Card, tool_data: Dictionary) -> void:
	# Инструменты открывают попап при клике
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_open_tool_popup(tool_data)

func _open_tool_popup(tool_data: Dictionary) -> void:
	# Открываем попап инструмента
	var popup = tool_popup_scene.instantiate()
	if (popupTools != null):
		if (popupTools.is_running != true):
			popupTools.queue_free()
			popupTools = popup
			popup_sound.play()
			add_child(popup)
		else:
			add_child(null)
	else:
		popupTools = popup
		popup_sound.play()
		add_child(popup)
		
	# Центрируем попап
	var pos=Vector2i((get_viewport_rect().size - popup.size))
	popup.position = Vector2i(pos.x/2,pos.y/2.5)
	
	# Настраиваем попап
	var upgrade_level = UpgradeManager.get_tool_level(tool_data.get("id", ""))
	popup.setup(tool_data, upgrade_level)
	
	# Подключаем сигнал завершения
	popup.finished.connect(_on_tool_finished)
	
	active_popups.append(popup)

func _on_tool_finished(product: Dictionary) -> void:
	if product.is_empty():
		return
	
	# Создаем карточку для готового продукта
	var card = _create_product_card(product)
	
	# Добавляем на первое свободное место в сетке
	for slot in grid_slots:
		if slot.contained_card == null:
			slot.set_card(card)
			break
	
	# Если нет свободного места, добавляем карточку на сцену
	if card.get_parent() == null:
		add_child(card)
		card.global_position = Vector2(100, 100)  # Временное положение
	
	# Уведомляем об создании продукта
	product_created.emit(product)
	
	# Изучаем рецепт, если это первый раз
	RecipeManager.learn_recipe(product.get("id", ""))



func _create_product_card(product: Dictionary) -> Card:
	var card = card_scene.instantiate()
	
	# Настраиваем карточку
	card.set_item({
		"id": product.get("id", ""),
		"name": product.get("name", "Продукт"),
		"sprite": product.get("sprite", "product_placeholder"),
		"type": product.get("type", "final_product"),
		"production_type": product.get("production_type", ""),
		"sell_prices": product.get("sell_prices", [0, 0, 0, 0])
	})
	
	# Устанавливаем качество
	card.set_quality(product.get("quality", 0))
	
	# Устанавливаем размер
	card.custom_minimum_size = card_size
	
	# Создаем всплывающее описание
	var popup = Label.new()
	popup.text = product.get("description", "")
	if product.has("sell_prices"):
		var prices = product["sell_prices"]
		popup.text += "\nЦена: "
		for i in range(min(4, prices.size())):
			popup.text += str(prices[i]) + "₽"
			if i < 3:
				popup.text += "/"
	
	popup.visible = false
	popup.name = "DescPopup"
	popup.autowrap_mode = TextServer.AUTOWRAP_WORD
	popup.custom_minimum_size = Vector2(150, 0)
	popup.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Создаем стиль для фона попапа
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	popup.add_theme_stylebox_override("normal", style)
	
	card.add_child(popup)
	
	# Добавляем метку для отображения качества
	var quality_label = Label.new()
	quality_label.name = "Quality"
	quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quality_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quality_label.add_theme_font_size_override("font_size", 14)  # Увеличенный шрифт
	card.add_child(quality_label)
	
	# Увеличиваем размер шрифта названия для лучшей читаемости
	if card.has_node("Label"):
		card.get_node("Label").add_theme_font_size_override("font_size", 14)
	
	return card

func _on_content_updated() -> void:
	# Обновляем ингредиенты и инструменты при изменении доступного контента
	_initialize_ingredients()
	_initialize_tools()
	_initialize_grid()  # Обновляем сетку при изменении уровня гаража

func move_to_warehouse(card: Card) -> void:
	if not card or not card.item_data:
		return
	
	var id = card.item_data.get("id", "")
	if id == "":
		return
	
	# Добавляем в хранилище
	if warehouse.has(id):
		warehouse[id].count += 1
	else:
		warehouse[id] = {
			"card": card,
			"count": 1
		}
	
	# Удаляем карточку из текущего слота
	if card.get_parent() is Slot:
		card.get_parent().remove_card()
		 
	# Обновляем состояние хранилища
	_update_warehouse_ui()

func _update_warehouse_ui() -> void:
	# Реализуем, если нужно визуальное представление хранилища
	pass

# Возвращает продукт из хранилища, если он есть
func get_product_from_warehouse(id: String) -> Card:
	if not warehouse.has(id) or warehouse[id].count <= 0:
		return null
	
	warehouse[id].count -= 1
	var card = warehouse[id].card.duplicate()
	
	# Если это был последний экземпляр, удаляем запись
	if warehouse[id].count <= 0:
		warehouse.erase(id)
	
	_update_warehouse_ui()
	return card
