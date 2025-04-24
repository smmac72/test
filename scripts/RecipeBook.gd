extends Panel
class_name RecipeBook

@onready var vbox: VBoxContainer = $Scroll/VBox
@onready var close_btn: Button = $Close

# Известные рецепты, хранятся как набор (Set) ID рецептов
var learned_recipes: Array = []

# Категории для группировки рецептов
var categories = {
	"samogon": "Самогон",
	"beer": "Пиво",
	"wine": "Вино"
}

# Сигналы
signal recipe_revealed(recipe_id)

func _ready() -> void:
	# Подключаем сигнал кнопки закрытия
	close_btn.pressed.connect(_on_close)
	
	# Начальное отображение
	_render_recipe_book()

func learn_recipe(recipe_id: String) -> void:
	# Проверяем, не изучен ли рецепт уже
	if recipe_id in learned_recipes:
		return
	
	# Добавляем рецепт в изученные
	learned_recipes.append(recipe_id)
	
	# Обновляем отображение
	_render_recipe_book()
	
	# Уведомляем об изучении рецепта
	recipe_revealed.emit(recipe_id)

func _render_recipe_book() -> void:
	# Очищаем содержимое
	for child in vbox.get_children():
		child.queue_free()
	
	# Группируем рецепты по категориям
	var categorized_recipes = {}
	
	# Инициализируем категории
	for cat_id in categories.keys():
		categorized_recipes[cat_id] = {
			"final_products": [],
			"intermediate_products": []
		}
	
	# Распределяем изученные рецепты по категориям
	for recipe_type in ["final_products", "intermediate_products"]:
		for recipe in DataService.recipes.get(recipe_type, []):
			var recipe_id = recipe.get("id", "")
			if recipe_id in learned_recipes:
				var prod_type = recipe.get("production_type", "")
				if prod_type in categorized_recipes:
					categorized_recipes[prod_type][recipe_type].append(recipe)
	
	# Добавляем неизвестные, но видимые рецепты
	for recipe_type in ["final_products", "intermediate_products"]:
		for recipe in DataService.recipes.get(recipe_type, []):
			var recipe_id = recipe.get("id", "")
			if recipe_id in DataService.visible_recipes and not (recipe_id in learned_recipes):
				var prod_type = recipe.get("production_type", "")
				if prod_type in categorized_recipes:
					# Добавляем как неизвестный рецепт
					var unknown_recipe = recipe.duplicate()
					unknown_recipe["unknown"] = true
					categorized_recipes[prod_type][recipe_type].append(unknown_recipe)
	
	# Создаем разделы для каждой категории
	for cat_id in categories.keys():
		var category_name = categories[cat_id]
		var has_recipes = false
		
		# Проверяем, есть ли рецепты в категории
		for recipe_type in categorized_recipes[cat_id].keys():
			if categorized_recipes[cat_id][recipe_type].size() > 0:
				has_recipes = true
				break
		
		if has_recipes:
			# Создаем заголовок категории
			var category_header = Label.new()
			category_header.text = category_name
			category_header.add_theme_font_size_override("font_size", 18)
			category_header.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
			vbox.add_child(category_header)
			
			# Добавляем готовые продукты
			if categorized_recipes[cat_id]["final_products"].size() > 0:
				var final_header = Label.new()
				final_header.text = "Готовые продукты"
				final_header.add_theme_font_size_override("font_size", 16)
				vbox.add_child(final_header)
				
				for recipe in categorized_recipes[cat_id]["final_products"]:
					_add_recipe_row(recipe)
			
			# Добавляем промежуточные продукты
			if categorized_recipes[cat_id]["intermediate_products"].size() > 0:
				var intermediate_header = Label.new()
				intermediate_header.text = "Промежуточные продукты"
				intermediate_header.add_theme_font_size_override("font_size", 16)
				vbox.add_child(intermediate_header)
				
				for recipe in categorized_recipes[cat_id]["intermediate_products"]:
					_add_recipe_row(recipe)
			
			# Добавляем разделитель
			var separator = HSeparator.new()
			separator.custom_minimum_size = Vector2(0, 10)
			vbox.add_child(separator)

func _add_recipe_row(recipe: Dictionary) -> void:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 30)
	
	# Иконка (если есть)
	var icon = TextureRect.new()
	if recipe.has("sprite") and not recipe.get("unknown", false):
		var path = "res://art/%s.png" % recipe.get("sprite", "placeholder")
		if ResourceLoader.exists(path):
			icon.texture = load(path)
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.SIZE_EXPAND_FILL
	
	row.add_child(icon)
	
	# Название
	var name_label = Label.new()
	name_label.text = recipe.get("name", "???")
	if recipe.get("unknown", false):
		name_label.text = "???"
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	row.add_child(name_label)
	
	# Кнопка информации (для изученных рецептов)
	if not recipe.get("unknown", false):
		var info_button = Button.new()
		info_button.text = "ℹ️"
		info_button.tooltip_text = "Показать рецепт"
		info_button.pressed.connect(_show_recipe_info.bind(recipe))
		row.add_child(info_button)
	
	vbox.add_child(row)

func _show_recipe_info(recipe: Dictionary) -> void:
	# Создаем всплывающее окно с информацией о рецепте
	var popup = AcceptDialog.new()
	popup.title = recipe.get("name", "Рецепт")
	
	var content = "%s\n\n" % recipe.get("description", "")
	
	# Ингредиенты
	content += "Ингредиенты:\n"
	for ingredient_id in recipe.get("ingredients", []):
		var ingredient_name = _get_ingredient_name(ingredient_id)
		content += "- %s\n" % ingredient_name
	
	# Инструмент
	var tool_id = recipe.get("tool_id", "")
	var tool_name = _get_tool_name(tool_id)
	content += "\nИнструмент: %s\n" % tool_name
	
	# Цены продажи (для финальных продуктов)
	if recipe.has("sell_prices"):
		content += "\nЦены продажи:\n"
		var prices = recipe["sell_prices"]
		for i in range(prices.size()):
			content += "⭐".repeat(i+1) + ": %d₽\n" % prices[i]
	
	popup.dialog_text = content
	add_child(popup)
	popup.popup_centered(Vector2(400, 300))

func _get_ingredient_name(ingredient_id: String) -> String:
	# Поиск ингредиента по ID
	for category in ["common", "samogon", "beer", "wine"]:
		if DataService.ingredients.has(category):
			for ingredient in DataService.ingredients[category]:
				if ingredient.get("id", "") == ingredient_id:
					return ingredient.get("name", ingredient_id)
	
	# Поиск в промежуточных продуктах
	for recipe in DataService.recipes.get("intermediate_products", []):
		if recipe.get("id", "") == ingredient_id:
			return recipe.get("name", ingredient_id)
	
	# Поиск в финальных продуктах
	for recipe in DataService.recipes.get("final_products", []):
		if recipe.get("id", "") == ingredient_id:
			return recipe.get("name", ingredient_id)
	
	return ingredient_id

func _get_tool_name(tool_id: String) -> String:
	# Поиск инструмента по ID
	for category in ["samogon", "beer", "wine"]:
		if DataService.tools.has(category):
			for tool in DataService.tools[category]:
				if tool.get("id", "") == tool_id:
					return tool.get("name", tool_id)
	
	return tool_id

func _on_close() -> void:
	visible = false
