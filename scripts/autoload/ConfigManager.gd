class_name ConfigManager
extends Node

# Синглтон для загрузки и управления всеми конфигурационными данными игры

signal configs_loaded

# Структуры данных для хранения конфигураций
var ingredients: Dictionary = {}
var tools: Dictionary = {}
var recipes: Dictionary = {}
var intermediate_products: Dictionary = {}
var final_products: Dictionary = {}
var upgrades: Dictionary = {}

# Пути к конфигурационным файлам
const INGREDIENTS_PATH = "res://data/configs/ingredients.json"
const TOOLS_PATH = "res://data/configs/tools.json"
const RECIPES_PATH = "res://data/configs/recipes.json"
const UPGRADES_PATH = "res://data/configs/upgrades.json"

# Флаг загрузки
var is_loaded: bool = false

func _ready() -> void:
	# Загружаем все конфигурации при инициализации
	load_all_configs()

func load_all_configs() -> void:
	load_ingredients()
	load_tools()
	load_recipes()
	load_upgrades()
	
	is_loaded = true
	emit_signal("configs_loaded")
	print("Все конфигурации успешно загружены")

# Загрузка ингредиентов
func load_ingredients() -> void:
	var json_data = load_json_file(INGREDIENTS_PATH)
	if json_data == null:
		push_error("Не удалось загрузить ингредиенты")
		return
	
	# Обработка общих ингредиентов
	if "common" in json_data:
		process_ingredient_category("common", json_data.common)
	
	# Обработка ингредиентов для самогона
	if "samogon" in json_data:
		process_ingredient_category("samogon", json_data.samogon)
	
	# Обработка ингредиентов для пива
	if "beer" in json_data:
		process_ingredient_category("beer", json_data.beer)
	
	# Обработка ингредиентов для вина
	if "wine" in json_data:
		process_ingredient_category("wine", json_data.wine)
	
	print("Загружено ингредиентов: ", ingredients.size())

# Обработка категории ингредиентов
func process_ingredient_category(category: String, items: Array) -> void:
	for item in items:
		var id = item.id
		ingredients[id] = item
		# Добавляем категорию для удобства фильтрации
		ingredients[id]["category"] = category

# Загрузка инструментов
func load_tools() -> void:
	var json_data = load_json_file(TOOLS_PATH)
	if json_data == null:
		push_error("Не удалось загрузить инструменты")
		return
	
	# Обработка инструментов для самогона
	if "samogon" in json_data:
		process_tool_category("samogon", json_data.samogon)
	
	# Обработка инструментов для пива
	if "beer" in json_data:
		process_tool_category("beer", json_data.beer)
	
	# Обработка инструментов для вина
	if "wine" in json_data:
		process_tool_category("wine", json_data.wine)
	
	print("Загружено инструментов: ", tools.size())

# Обработка категории инструментов
func process_tool_category(category: String, items: Array) -> void:
	for item in items:
		var id = item.id
		tools[id] = item
		# Добавляем категорию для удобства фильтрации
		tools[id]["category"] = category

# Загрузка рецептов
func load_recipes() -> void:
	var json_data = load_json_file(RECIPES_PATH)
	if json_data == null:
		push_error("Не удалось загрузить рецепты")
		return
	
	# Обработка промежуточных продуктов
	if "intermediate_products" in json_data:
		for item in json_data.intermediate_products:
			var id = item.id
			intermediate_products[id] = item
	
	# Обработка конечных продуктов
	if "final_products" in json_data:
		for item in json_data.final_products:
			var id = item.id
			final_products[id] = item
	
	# Объединяем в общий словарь рецептов
	recipes = intermediate_products.duplicate()
	recipes.merge(final_products)
	
	print("Загружено промежуточных продуктов: ", intermediate_products.size())
	print("Загружено конечных продуктов: ", final_products.size())

# Загрузка улучшений
func load_upgrades() -> void:
	var json_data = load_json_file(UPGRADES_PATH)
	if json_data == null:
		push_error("Не удалось загрузить улучшения")
		return
	
	# Обработка улучшений для самогона
	if "samogon" in json_data:
		process_upgrade_category("samogon", json_data.samogon)
	
	# Обработка улучшений для пива
	if "beer" in json_data:
		process_upgrade_category("beer", json_data.beer)
	
	# Обработка улучшений для вина
	if "wine" in json_data:
		process_upgrade_category("wine", json_data.wine)
	
	# Обработка улучшений для гаража
	if "garage" in json_data:
		process_upgrade_category("garage", json_data.garage)
	
	print("Загружено улучшений: ", upgrades.size())

# Обработка категории улучшений
func process_upgrade_category(category: String, items: Array) -> void:
	# Если категория еще не существует, создаем словарь для уровней
	if not category in upgrades:
		upgrades[category] = {}
	
	for item in items:
		var id = item.id
		var level = item.level
		
		# Сохраняем по уровню для удобства доступа
		upgrades[category][level] = item

# Загрузка JSON файла
func load_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Файл не найден: " + path)
		return null
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("Ошибка парсинга JSON: " + path + " на строке " + str(json.get_error_line()) + ": " + json.get_error_message())
		return null
	
	return json.get_data()

# Методы доступа к данным

# Получение всех ингредиентов по типу производства
func get_ingredients_by_production_type(production_type: String) -> Array:
	var result = []
	
	for id in ingredients:
		var ingredient = ingredients[id]
		if ingredient.production_type == production_type or ingredient.production_type == "all":
			result.append(ingredient)
	
	return result

# Получение всех инструментов по типу производства
func get_tools_by_production_type(production_type: String) -> Array:
	var result = []
	
	for id in tools:
		var tool = tools[id]
		if tool.production_type == production_type:
			result.append(tool)
	
	return result

# Получение всех промежуточных продуктов по типу производства
func get_intermediate_products_by_production_type(production_type: String) -> Array:
	var result = []
	
	for id in intermediate_products:
		var product = intermediate_products[id]
		if product.production_type == production_type:
			result.append(product)
	
	return result

# Получение всех конечных продуктов по типу производства
func get_final_products_by_production_type(production_type: String) -> Array:
	var result = []
	
	for id in final_products:
		var product = final_products[id]
		if product.production_type == production_type:
			result.append(product)
	
	return result

# Получение рецепта по ID продукта
func get_recipe_by_product_id(product_id: String) -> Dictionary:
	if product_id in recipes:
		return recipes[product_id]
	return {}

# Получение улучшения по типу производства и уровню
func get_upgrade(production_type: String, level: int) -> Dictionary:
	if production_type in upgrades and level in upgrades[production_type]:
		return upgrades[production_type][level]
	return {}

# Получение списка разблокированных ингредиентов для уровня производства
func get_unlocked_ingredients(production_type: String, level: int) -> Array:
	var result = []
	
	# Добавляем базовые ингредиенты, доступные всегда
	for id in ingredients:
		var ingredient = ingredients[id]
		if ingredient.production_type == "all":
			result.append(id)
	
	# Проходим по всем уровням до текущего и собираем разблокированные ингредиенты
	for l in range(1, level + 1):
		var upgrade = get_upgrade(production_type, l)
		if upgrade.size() > 0 and "unlocks" in upgrade and "ingredients" in upgrade.unlocks:
			result.append_array(upgrade.unlocks.ingredients)
	
	return result

# Получение списка разблокированных инструментов для уровня производства
func get_unlocked_tools(production_type: String, level: int) -> Array:
	var result = []
	
	# Проходим по всем уровням до текущего и собираем разблокированные инструменты
	for l in range(1, level + 1):
		var upgrade = get_upgrade(production_type, l)
		if upgrade.size() > 0 and "unlocks" in upgrade and "tools" in upgrade.unlocks:
			result.append_array(upgrade.unlocks.tools)
	
	return result

# Получение списка разблокированных рецептов для уровня производства
func get_unlocked_recipes(production_type: String, level: int) -> Array:
	var result = []
	
	# Проходим по всем уровням до текущего и собираем разблокированные рецепты
	for l in range(1, level + 1):
		var upgrade = get_upgrade(production_type, l)
		if upgrade.size() > 0 and "unlocks" in upgrade and "recipes" in upgrade.unlocks:
			result.append_array(upgrade.unlocks.recipes)
	
	return result

# Получение размера сетки для уровня гаража
func get_garage_grid_size(level: int) -> Vector2:
	var upgrade = get_upgrade("garage", level)
	if upgrade.size() > 0 and "grid_size" in upgrade:
		return Vector2(upgrade.grid_size.width, upgrade.grid_size.height)
	
	# Возвращаем размер по умолчанию, если не найдено
	return Vector2(5, 3)
