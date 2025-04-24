extends Panel
class_name WarehousePanel

# Ссылка на склад
var warehouse: Warehouse

# UI компоненты
@onready var tabs := $VBox/TabContainer
@onready var samogon_grid := $VBox/TabContainer/Самогон/GridContainer
@onready var beer_grid := $VBox/TabContainer/Пиво/GridContainer
@onready var wine_grid := $VBox/TabContainer/Вино/GridContainer
@onready var other_grid := $VBox/TabContainer/Прочее/GridContainer
@onready var close_button := $VBox/CloseButton

# Сцены
var card_scene = preload("res://scenes/widgets/Card.tscn")

# Сигналы
signal item_selected(item_id, quality)
signal warehouse_closed

func _ready():
	# Проверяем наличие склада
	if warehouse == null:
		warehouse = Warehouse.new()
	
	# Подключаем сигналы
	warehouse.storage_updated.connect(_update_display)
	close_button.pressed.connect(_on_close_pressed)
	
	# Обновляем отображение
	_update_display()

func set_warehouse(wh: Warehouse):
	warehouse = wh
	warehouse.storage_updated.connect(_update_display)
	_update_display()

func _update_display():
	# Очищаем сетки
	_clear_grids()
	
	# Получаем продукты по категориям
	var categorized = warehouse.get_items_by_category()
	
	# Заполняем каждую категорию
	_fill_grid(samogon_grid, categorized.get("samogon", {}))
	_fill_grid(beer_grid, categorized.get("beer", {}))
	_fill_grid(wine_grid, categorized.get("wine", {}))
	
	# В "Прочее" добавляем все остальные категории
	var other_items = {}
	for category in categorized:
		if category != "samogon" and category != "beer" and category != "wine":
			other_items.merge(categorized[category])
	
	_fill_grid(other_grid, other_items)
	
	# Обновляем метки на вкладках
	_update_tab_labels()

func _clear_grids():
	for child in samogon_grid.get_children():
		child.queue_free()
	
	for child in beer_grid.get_children():
		child.queue_free()
	
	for child in wine_grid.get_children():
		child.queue_free()
	
	for child in other_grid.get_children():
		child.queue_free()

func _fill_grid(grid: GridContainer, items: Dictionary):
	for item_id in items:
		# Получаем данные продукта
		var item_data = items[item_id]
		
		# Создаем карточку
		var card = warehouse.create_product_card(item_id, card_scene)
		
		if card:
			# Добавляем в сетку
			grid.add_child(card)
			
			# Добавляем обработчик нажатия
			card.gui_input.connect(_on_card_input.bind(card, item_id))

func _update_tab_labels():
	# Получаем продукты по категориям
	var categorized = warehouse.get_items_by_category()
	
	# Подсчитываем количество продуктов в каждой категории
	var samogon_count = 0
	if categorized.has("samogon"):
		for item_id in categorized["samogon"]:
			samogon_count += categorized["samogon"][item_id]["count"]
	
	var beer_count = 0
	if categorized.has("beer"):
		for item_id in categorized["beer"]:
			beer_count += categorized["beer"][item_id]["count"]
	
	var wine_count = 0
	if categorized.has("wine"):
		for item_id in categorized["wine"]:
			wine_count += categorized["wine"][item_id]["count"]
	
	var other_count = 0
	for category in categorized:
		if category != "samogon" and category != "beer" and category != "wine":
			for item_id in categorized[category]:
				other_count += categorized[category][item_id]["count"]
	
	# Обновляем названия вкладок
	tabs.set_tab_title(0, "Самогон (%d)" % samogon_count)
	tabs.set_tab_title(1, "Пиво (%d)" % beer_count)
	tabs.set_tab_title(2, "Вино (%d)" % wine_count)
	tabs.set_tab_title(3, "Прочее (%d)" % other_count)

func _on_card_input(event: InputEvent, card: Card, item_id: String):
	# Обработка нажатия на карточку
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Получаем качество продукта
		var quality = warehouse.get_item_quality(item_id)
		
		# Уведомляем о выборе продукта
		item_selected.emit(item_id, quality)
		
		# Удаляем продукт со склада
		warehouse.remove_item(item_id, 1)
		
		# Обновляем отображение
		_update_display()

func _on_close_pressed():
	# Скрываем панель и уведомляем о закрытии
	visible = false
	warehouse_closed.emit()

# Создание пустой панели склада
static func create(parent: Node) -> WarehousePanel:
	# Создаем панель
	var panel = load("res://scenes/widgets/WarehousePanel.tscn").instantiate() as WarehousePanel
	
	# Настраиваем
	panel.position = Vector2(100, 100)
	
	# Добавляем на сцену
	parent.add_child(panel)
	
	return panel
