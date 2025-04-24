extends Node

# Данные игры
var ingredients := {}
var recipes     := {}
var tools       := {}
var customers   := {}
var upgrades    := {}

# Списки доступного контента
var visible_ingredients : Array = []
var visible_tools       : Array = []
var visible_recipes     : Array = []

# Сигналы
signal content_updated

func _ready() -> void:
	# Загружаем JSON-данные
	_load_json("res://data/ingredients.json", ingredients)
	_load_json("res://data/recipes.json",     recipes)
	_load_json("res://data/customers.json",   customers)
	_load_json("res://data/upgrades.json",    upgrades)
	_load_json("res://data/tools.json",       tools)
	
	# Инициализируем содержимое для базового уровня
	_initialize_base_content()

func _load_json(path: String, target: Dictionary) -> void:
	if not ResourceLoader.exists(path):
		push_error("%s not found" % path)
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var txt: String = file.get_as_text()
		var parsed = JSON.parse_string(txt)
		if parsed is Dictionary:
			target.merge(parsed, true)
		file.close()

func _initialize_base_content() -> void:
	# Установка начального содержимого (для уровня 1 самогоноварения)
	visible_ingredients = ["water", "sugar", "koji"]
	visible_tools = ["fermentation", "distiller"]
	visible_recipes = ["sugar_mash", "moonshine"]
	
	# Если уже есть сохраненные улучшения, применяем их
	for category in upgrades.keys():
		for upgrade_data in upgrades[category]:
			if upgrade_data.get("level", 0) <= 1:  # Базовый уровень
				apply_upgrade(upgrade_data)

func apply_upgrade(upgrade_data: Dictionary) -> void:
	if not upgrade_data.has("unlocks"):
		return
	
	var unlocks = upgrade_data["unlocks"]
	
	# Разблокируем ингредиенты
	if unlocks.has("ingredients"):
		for ingredient_id in unlocks["ingredients"]:
			if not ingredient_id in visible_ingredients:
				visible_ingredients.append(ingredient_id)
	
	# Разблокируем инструменты
	if unlocks.has("tools"):
		for tool_id in unlocks["tools"]:
			if not tool_id in visible_tools:
				visible_tools.append(tool_id)
	
	# Разблокируем рецепты
	if unlocks.has("recipes"):
		for recipe_id in unlocks["recipes"]:
			if not recipe_id in visible_recipes:
				visible_recipes.append(recipe_id)
	
	# Уведомляем об обновлении содержимого
	content_updated.emit()

func find_item(id: String) -> Dictionary:
	# Поиск ингредиента по ID
	for category in ["common", "samogon", "beer", "wine"]:
		if ingredients.has(category):
			for item in ingredients[category]:
				if item.get("id", "") == id:
					return item
	
	# Поиск промежуточного продукта
	for item in recipes.get("intermediate_products", []):
		if item.get("id", "") == id:
			return item
	
	# Поиск финального продукта
	for item in recipes.get("final_products", []):
		if item.get("id", "") == id:
			return item
	
	return {}

func find_recipe_by_product(product_id: String) -> Dictionary:
	# Поиск рецепта по ID продукта
	for recipe in recipes.get("intermediate_products", []):
		if recipe.get("id", "") == product_id:
			return recipe
	
	for recipe in recipes.get("final_products", []):
		if recipe.get("id", "") == product_id:
			return recipe
	
	return {}

func find_tool(tool_id: String) -> Dictionary:
	# Поиск инструмента по ID
	for category in ["samogon", "beer", "wine"]:
		if tools.has(category):
			for tool in tools[category]:
				if tool.get("id", "") == tool_id:
					return tool
	
	return {}

func get_price(product_id: String, quality: int) -> int:
	# Получаем цену продукта для указанного качества
	var product = find_item(product_id)
	
	if product.has("sell_prices"):
		var prices = product["sell_prices"]
		if quality >= 0 and quality < prices.size():
			return prices[quality]
	
	return 0

func get_ingredient_price(ingredient_id: String, quality: int) -> int:
	# Получаем цену ингредиента для указанного качества
	var ingredient = find_item(ingredient_id)
	
	if ingredient.has("quality_prices"):
		var prices = ingredient["quality_prices"]
		if quality >= 0 and quality < prices.size():
			return prices[quality]
	
	return 0

# Сохранение и загрузка
func save_data() -> Dictionary:
	return {
		"visible_ingredients": visible_ingredients,
		"visible_tools": visible_tools,
		"visible_recipes": visible_recipes
	}

func load_data(data: Dictionary) -> void:
	if data.has("visible_ingredients"):
		visible_ingredients = data["visible_ingredients"]
	
	if data.has("visible_tools"):
		visible_tools = data["visible_tools"]
	
	if data.has("visible_recipes"):
		visible_recipes = data["visible_recipes"]
	
	content_updated.emit()
