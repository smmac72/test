class_name ProductionUI
extends Control

# Секция производства (правое окно из дизайн-документа)

# Узлы компонентов UI
@onready var grid_container: GridContainer = $VBoxContainer/ProductionArea/Grid
@onready var ingredients_bar: HBoxContainer = $VBoxContainer/IngredientsPanel/IngredientsBar
@onready var tools_bar: HBoxContainer = $VBoxContainer/ToolsPanel/ToolsBar
@onready var recipe_book_button: Button = $VBoxContainer/ButtonPanel/HBoxContainer/RecipeBookButton
@onready var upgrade_button: Button = $VBoxContainer/ButtonPanel/HBoxContainer/UpgradeButton
@onready var popup_container: Control = $PopupContainer
@onready var card_popup: Panel = $PopupContainer/CardPopup
@onready var recipe_book: Panel = $PopupContainer/RecipeBook

# Текущий выбранный тип производства
var current_production_type: String = "samogon"

# Ссылки на другие системы
@onready var production_manager: ProductionManager = $"/root/ProductionManager"
@onready var game_manager: GameManager = $"/root/GameManager"
@onready var audio_manager: AudioManager = $"/root/AudioManager"

# Инициализация интерфейса
func _ready() -> void:
	# Подключаем сигналы
	recipe_book_button.connect("pressed", _on_recipe_book_button_pressed)
	upgrade_button.connect("pressed", _on_upgrade_button_pressed)
	
	# Подключаем сигналы системы производства
	production_manager.connect("recipe_completed", _on_recipe_completed)
	production_manager.connect("product_count_changed", _on_product_count_changed)
	production_manager.connect("product_quality_improved", _on_product_quality_improved)
	production_manager.connect("tool_quality_improved", _on_tool_quality_improved)
	production_manager.connect("recipe_learned", _on_recipe_learned)
	
	# Инициализируем UI для текущего типа производства
	update_production_ui()
	
	# Скрываем попапы
	hide_popups()

# Обновление интерфейса при изменении типа производства
func update_production_ui() -> void:
	# Очищаем текущий UI
	clear_ui()
	
	# Загружаем ингредиенты
	load_ingredients()
	
	# Загружаем инструменты
	load_tools()
	
	# Обновляем сетку
	update_grid()
	
	# Обновляем книгу рецептов
	update_recipe_book()

# Очистка текущего UI
func clear_ui() -> void:
	# Очищаем панель ингредиентов
	for child in ingredients_bar.get_children():
		child.queue_free()
	
	# Очищаем панель инструментов
	for child in tools_bar.get_children():
		child.queue_free()

# Загрузка ингредиентов для текущего типа производства
func load_ingredients() -> void:
	var ingredients = production_manager.get_ingredients_by_type(current_production_type)
	
	for ingredient in ingredients:
		# Создаем карточку ингредиента
		var card = preload("res://scenes/production/IngredientCard.tscn").instantiate()
		card.setup(ingredient)
		card.connect("card_clicked", _on_card_clicked)
		card.connect("card_drag_started", _on_card_drag_started)
		card.connect("card_drag_ended", _on_card_drag_ended)
		ingredients_bar.add_child(card)

# Загрузка инструментов для текущего типа производства
func load_tools() -> void:
	var tools = production_manager.get_tools_by_type(current_production_type)
	
	for tool_data in tools:
		# Создаем карточку инструмента
		var card = preload("res://scenes/production/ToolCard.tscn").instantiate()
		card.setup(tool_data)
		card.connect("card_clicked", _on_card_clicked)
		card.connect("card_drag_started", _on_card_drag_started)
		card.connect("card_drag_ended", _on_card_drag_ended)
		tools_bar.add_child(card)

# Обновление сетки для размещения карточек
func update_grid() -> void:
	# Получаем размер сетки для текущего уровня гаража
	var garage_level = game_manager.production_levels.get("garage", 1)
	var grid_size = production_manager.config_manager.get_garage_grid_size(garage_level)
	
	# Настраиваем размеры сетки
	grid_container.columns = grid_size.x
	
	# Очищаем текущую сетку
	for child in grid_container.get_children():
		child.queue_free()
	
	# Создаем новые ячейки
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell = preload("res://scenes/production/GridCell.tscn").instantiate()
			cell.cell_position = Vector2i(x, y)
			cell.connect("cell_highlighted", _on_cell_highlighted)
			cell.connect("cell_unhighlighted", _on_cell_unhighlighted)
			cell.connect("item_dropped", _on_item_dropped_to_cell)
			grid_container.add_child(cell)

# Обновление книги рецептов
func update_recipe_book() -> void:
	if recipe_book:
		recipe_book.update_recipes(current_production_type, production_manager.learned_recipes)

# Обработчик нажатия на кнопку книги рецептов
func _on_recipe_book_button_pressed() -> void:
	# Показываем или скрываем книгу рецептов
	if recipe_book.visible:
		recipe_book.hide()
	else:
		hide_popups()
		recipe_book.show()
		recipe_book.update_recipes(current_production_type, production_manager.learned_recipes)
		
		# Воспроизводим звук
		if audio_manager:
			audio_manager.play_sound("popup_open", AudioManager.SoundType.UI)

# Обработчик нажатия на кнопку улучшения
func _on_upgrade_button_pressed() -> void:
	# Показываем меню улучшения
	hide_popups()
	var upgrade_menu = preload("res://scenes/ui/UpgradeMenu.tscn").instantiate()
	upgrade_menu.connect("upgrade_selected", _on_upgrade_selected)
	popup_container.add_child(upgrade_menu)
	upgrade_menu.popup_centered()
	
	# Воспроизводим звук
	if audio_manager:
		audio_manager.play_sound("popup_open", AudioManager.SoundType.UI)

# Обработчик нажатия на карточку
func _on_card_clicked(card_data) -> void:
	# Показываем информацию о карточке
	show_card_popup(card_data)

# Показ всплывающего окна с информацией о карточке
func show_card_popup(card_data) -> void:
	hide_popups()
	
	# Настраиваем и показываем popup
	card_popup.setup(card_data)
	card_popup.connect("buy_pressed", _on_popup_buy_pressed)
	card_popup.connect("improve_pressed", _on_popup_improve_pressed)
	card_popup.connect("discard_pressed", _on_popup_discard_pressed)
	card_popup.connect("close_pressed", _on_popup_close_pressed)
	card_popup.show()
	
	# Воспроизводим звук
	if audio_manager:
		audio_manager.play_sound("popup_open", AudioManager.SoundType.UI)

# Скрытие всех всплывающих окон
func hide_popups() -> void:
	# Скрываем popup карточки
	if card_popup:
		card_popup.hide()
	
	# Скрываем книгу рецептов
	if recipe_book:
		recipe_book.hide()
	
	# Удаляем все другие временные попапы
	for child in popup_container.get_children():
		if child != card_popup and child != recipe_book:
			child.queue_free()

# Обработчики кнопок в попапе карточки
func _on_popup_buy_pressed(card_data, amount: int) -> void:
	if card_data is IngredientData:
		production_manager.buy_ingredient(card_data.id, amount)
		card_popup.update_content()  # Обновляем информацию в попапе
		
		# Воспроизводим звук покупки
		if audio_manager:
			audio_manager.play_sound("money_loss", AudioManager.SoundType.UI)

func _on_popup_improve_pressed(card_data) -> void:
	if card_data is IngredientData:
		if production_manager.improve_ingredient(card_data.id):
			card_popup.update_content()  # Обновляем информацию в попапе
			
			# Воспроизводим звук улучшения
			if audio_manager:
				audio_manager.play_sound("money_loss", AudioManager.SoundType.UI)
	elif card_data is ToolData:
		if production_manager.improve_tool(card_data.id):
			card_popup.update_content()  # Обновляем информацию в попапе
			
			# Воспроизводим звук улучшения
			if audio_manager:
				audio_manager.play_sound("money_loss", AudioManager.SoundType.UI)

func _on_popup_discard_pressed(card_data) -> void:
	# Логика удаления продукта
	if card_data is ProductData:
		# Уменьшаем количество продукта
		card_data.count -= 1
		if card_data.count < 0:
			card_data.count = 0
		
		# Обновляем UI
		production_manager.emit_signal("product_count_changed", card_data.id, card_data.count, false)
		card_popup.update_content()  # Обновляем информацию в попапе
		
		# Воспроизводим звук удаления
		if audio_manager:
			audio_manager.play_sound("item_drop", AudioManager.SoundType.GAMEPLAY)

func _on_popup_close_pressed() -> void:
	hide_popups()
	
	# Воспроизводим звук закрытия
	if audio_manager:
		audio_manager.play_sound("popup_close", AudioManager.SoundType.UI)

# Обработчики событий перетаскивания карточек
func _on_card_drag_started(card_node) -> void:
	# Воспроизводим звук начала перетаскивания
	if audio_manager:
		audio_manager.play_sound("item_pickup", AudioManager.SoundType.GAMEPLAY)

func _on_card_drag_ended(card_node, drop_position: Vector2) -> void:
	# Проверяем, находится ли позиция над допустимой целью
	# Если нет, возвращаем карточку на место
	card_node.return_to_original()
	
	# Воспроизводим звук окончания перетаскивания
	if audio_manager:
		audio_manager.play_sound("item_drop", AudioManager.SoundType.GAMEPLAY)

# Обработчики событий взаимодействия с ячейками сетки
func _on_cell_highlighted(cell) -> void:
	# Визуальное выделение ячейки
	cell.highlight_as_target(true)

func _on_cell_unhighlighted(cell) -> void:
	# Снятие выделения ячейки
	cell.remove_highlight()

func _on_item_dropped_to_cell(cell, item_data) -> void:
	# Логика размещения предмета в ячейку сетки
	if item_data is ToolData:
		# Создаем экземпляр инструмента в ячейке
		var tool_instance = preload("res://scenes/production/ToolInstance.tscn").instantiate()
		tool_instance.tool_id = item_data.id
		tool_instance.position = cell.get_global_center()
		add_child(tool_instance)
		
		# Обновляем состояние ячейки
		cell.set_content(tool_instance)
		
		# Воспроизводим звук размещения
		if audio_manager:
			audio_manager.play_sound("item_place", AudioManager.SoundType.GAMEPLAY)
	elif item_data is IngredientData:
		# Проверяем, есть ли в ячейке инструмент
		var cell_content = cell.content
		if cell_content is ToolInstance:
			# Пытаемся добавить ингредиент в инструмент
			# Эта логика должна быть реализована в ToolInstance
			pass
		
	elif item_data is ProductData:
		# Размещаем продукт в ячейке (если это промежуточный продукт)
		if not item_data.is_final:
			var product_instance = preload("res://scenes/production/ProductInstance.tscn").instantiate()
			product_instance.setup(item_data)
			product_instance.position = cell.get_global_center()
			add_child(product_instance)
			
			# Обновляем состояние ячейки
			cell.set_content(product_instance)
			
			# Уменьшаем количество продукта в инвентаре
			item_data.count -= 1
			production_manager.emit_signal("product_count_changed", item_data.id, item_data.count, false)
			
			# Воспроизводим звук размещения
			if audio_manager:
				audio_manager.play_sound("item_place", AudioManager.SoundType.GAMEPLAY)

# Обработчик события создания продукта
func _on_recipe_completed(product_id: String, quality: int) -> void:
	# Создаем временное уведомление о созданном продукте
	var product = production_manager.get_product(product_id)
	if product:
		show_notification("Создан: " + product.name + " (качество: " + str(quality) + ")")
	
	# Обновляем книгу рецептов, если она открыта
	if recipe_book.visible:
		recipe_book.update_recipes(current_production_type, production_manager.learned_recipes)
	
	# Воспроизводим звук завершения создания
	if audio_manager:
		audio_manager.play_sound("production_complete", AudioManager.SoundType.GAMEPLAY)

# Обработчик изменения количества продукта
func _on_product_count_changed(product_id: String, new_count: int, is_ingredient: bool) -> void:
	# Обновляем соответствующие карточки в UI
	var target_container = ingredients_bar if is_ingredient else null
	
	# Если это не ингредиент, ищем среди продуктов на сетке
	if not target_container:
		# Обновление будет через ProductInstance
		return
	
	# Обновляем карточку в панели ингредиентов
	for card in target_container.get_children():
		if card.has_method("get_item_id") and card.get_item_id() == product_id:
			card.update_count(new_count)
			break

# Обработчик улучшения качества продукта
func _on_product_quality_improved(product_id: String, new_quality: int) -> void:
	# Обновляем соответствующие карточки в UI
	for card in ingredients_bar.get_children():
		if card.has_method("get_item_id") and card.get_item_id() == product_id:
			card.update_quality(new_quality)
			break
	
	# Показываем уведомление
	show_notification("Улучшено качество ингредиента до " + str(new_quality))

# Обработчик улучшения качества инструмента
func _on_tool_quality_improved(tool_id: String, new_quality: int) -> void:
	# Обновляем соответствующие карточки в UI
	for card in tools_bar.get_children():
		if card.has_method("get_item_id") and card.get_item_id() == tool_id:
			card.update_quality(new_quality)
			break
	
	# Показываем уведомление
	show_notification("Улучшено качество инструмента до " + str(new_quality))

# Обработчик изучения нового рецепта
func _on_recipe_learned(recipe_id: String) -> void:
	# Показываем уведомление
	var product = production_manager.get_product(recipe_id)
	if product:
		show_notification("Открыт новый рецепт: " + product.name)
	
	# Обновляем книгу рецептов, если она открыта
	if recipe_book.visible:
		recipe_book.update_recipes(current_production_type, production_manager.learned_recipes)

# Обработчик выбора улучшения
func _on_upgrade_selected(upgrade_id: String) -> void:
	var upgrade_data = null
	var production_type = ""
	
	# Находим данные улучшения
	var config_manager = $"/root/ConfigManager"
	for type in config_manager.upgrades:
		for level in config_manager.upgrades[type]:
			var upgrade = config_manager.upgrades[type][level]
			if upgrade.id == upgrade_id:
				upgrade_data = upgrade
				production_type = type
				break
	
	if upgrade_data:
		# Проверяем возможность покупки
		if game_manager.money >= upgrade_data.cost:
			# Покупаем улучшение
			game_manager.change_money(-upgrade_data.cost, "Улучшение: " + upgrade_data.name)
			
			# Повышаем уровень производства
			game_manager.production_levels[production_type] = upgrade_data.level
			
			# Разблокируем новый контент
			production_manager.unlock_production_level(production_type, upgrade_data.level)
			
			# Если это улучшение гаража, обновляем сетку
			if production_type == "garage":
				update_grid()
			else:
				# Обновляем UI
				update_production_ui()
			
			# Показываем уведомление
			show_notification("Приобретено улучшение: " + upgrade_data.name)
			
			# Воспроизводим звук покупки
			if audio_manager:
				audio_manager.play_sound("money_loss", AudioManager.SoundType.UI)
		else:
			# Недостаточно денег
			show_notification("Недостаточно денег для покупки улучшения!")

# Показ временного уведомления
func show_notification(text: String) -> void:
	var notification = preload("res://scenes/ui/Notification.tscn").instantiate()
	notification.setup(text)
	add_child(notification)
	
	# Воспроизводим звук уведомления
	if audio_manager:
		audio_manager.play_sound("popup_open", AudioManager.SoundType.UI)

# Установка текущего типа производства
func set_production_type(type: String) -> void:
	if current_production_type != type:
		current_production_type = type
		update_production_ui()
