class_name ProductionManager
extends Node

# Сигналы для взаимодействия с другими системами
signal recipe_completed(product_id: String, quality: int)
signal product_count_changed(product_id: String, new_count: int, is_ingredient: bool)
signal product_quality_improved(product_id: String, new_quality: int)
signal tool_quality_improved(tool_id: String, new_quality: int)
signal recipe_learned(recipe_id: String)
signal production_initialized

# Данные о доступных предметах
var available_ingredients: Dictionary = {}  # id -> IngredientData
var available_tools: Dictionary = {}        # id -> ToolData
var available_products: Dictionary = {}     # id -> ProductData
var learned_recipes: Dictionary = {}        # id -> bool

# Флаги состояния
var _is_initialized: bool = false

# Ссылки на другие системы
@onready var config_manager: ConfigManager = $"/root/ConfigManager"
@onready var game_manager: GameManager = $"/root/GameManager"
@onready var audio_manager: AudioManager = $"/root/AudioManager"
@onready var save_manager: SaveManager = $"/root/SaveManager"

# Инициализация системы производства
func _ready() -> void:
	# Регистрируем систему в SaveManager
	if save_manager:
		save_manager.register_system("production", self)
	
	# Дожидаемся загрузки конфигураций
	if not config_manager.is_loaded:
		await config_manager.configs_loaded

	# Подключаем сигналы
	if game_manager:
		game_manager.connect("game_initialized", _on_game_initialized)

# Обработчик инициализации игры
func _on_game_initialized() -> void:
	# Не выполняем инициализацию дважды
	if _is_initialized:
		return
	
	_is_initialized = true
	initialize_with_levels(game_manager.production_levels)
	emit_signal("production_initialized")

# Инициализация с учетом текущих уровней производства
func initialize_with_levels(production_levels: Dictionary) -> void:
	# Сбрасываем текущие данные
	available_ingredients.clear()
	available_tools.clear()
	available_products.clear()
	learned_recipes.clear()
	
	# Загружаем доступные ингредиенты, инструменты и рецепты
	for production_type in production_levels:
		var level = production_levels[production_type]
		if level > 0:
			load_production_content(production_type, level)

# Загрузка контента для типа производства и уровня
func load_production_content(production_type: String, level: int) -> void:
	# Загружаем базовые ингредиенты, доступные всегда
	load_common_ingredients()
	
	# Загружаем разблокированные ингредиенты
	var unlocked_ingredients = config_manager.get_unlocked_ingredients(production_type, level)
	for ingredient_id in unlocked_ingredients:
		if ingredient_id in config_manager.ingredients:
			var ingredient_data = IngredientData.from_dict(config_manager.ingredients[ingredient_id])
			available_ingredients[ingredient_id] = ingredient_data
	
	# Загружаем разблокированные инструменты
	var unlocked_tools = config_manager.get_unlocked_tools(production_type, level)
	for tool_id in unlocked_tools:
		if tool_id in config_manager.tools:
			var tool_data = ToolData.from_dict(config_manager.tools[tool_id])
			available_tools[tool_id] = tool_data
	
	# Загружаем разблокированные рецепты
	var unlocked_recipes = config_manager.get_unlocked_recipes(production_type, level)
	for recipe_id in unlocked_recipes:
		# Проверяем, промежуточный это продукт или конечный
		if recipe_id in config_manager.intermediate_products:
			var product_data = ProductData.from_intermediate_dict(config_manager.intermediate_products[recipe_id])
			available_products[recipe_id] = product_data
			learned_recipes[recipe_id] = true
		elif recipe_id in config_manager.final_products:
			var product_data = ProductData.from_final_dict(config_manager.final_products[recipe_id])
			available_products[recipe_id] = product_data
			learned_recipes[recipe_id] = true

# Загрузка общих ингредиентов
func load_common_ingredients() -> void:
	for ingredient_id in config_manager.ingredients:
		var ingredient = config_manager.ingredients[ingredient_id]
		if ingredient.production_type == "all":
			var ingredient_data = IngredientData.from_dict(ingredient)
			available_ingredients[ingredient_id] = ingredient_data

# Разблокировка нового уровня производства
func unlock_production_level(production_type: String, level: int) -> void:
	load_production_content(production_type, level)

# Получение данных об ингредиенте по ID
func get_ingredient(ingredient_id: String) -> IngredientData:
	if ingredient_id.is_empty():
		push_warning("ProductionManager: запрос ингредиента с пустым ID")
		return null
	
	if ingredient_id in available_ingredients:
		return available_ingredients[ingredient_id]
	
	push_warning("ProductionManager: ингредиент с ID '" + ingredient_id + "' не найден")
	return null

# Получение данных об инструменте по ID
func get_tool(tool_id: String) -> ToolData:
	if tool_id.is_empty():
		push_warning("ProductionManager: запрос инструмента с пустым ID")
		return null
	
	if tool_id in available_tools:
		return available_tools[tool_id]
	
	push_warning("ProductionManager: инструмент с ID '" + tool_id + "' не найден")
	return null

# Получение данных о продукте по ID
func get_product(product_id: String) -> ProductData:
	if product_id.is_empty():
		push_warning("ProductionManager: запрос продукта с пустым ID")
		return null
	
	if product_id in available_products:
		return available_products[product_id]
	
	push_warning("ProductionManager: продукт с ID '" + product_id + "' не найден")
	return null

# Проверка наличия ингредиентов для рецепта
func can_craft_recipe(recipe_id: String) -> bool:
	if not recipe_id in available_products:
		return false
	
	var product = available_products[recipe_id]
	var tool_id = product.tool_id
	
	# Проверяем наличие инструмента
	if not tool_id in available_tools:
		return false
	
	# Проверяем наличие всех ингредиентов
	for ingredient_id in product.ingredients:
		var is_available = false
		
		# Проверяем среди базовых ингредиентов
		if ingredient_id in available_ingredients:
			if available_ingredients[ingredient_id].count > 0:
				is_available = true
		
		# Проверяем среди продуктов
		elif ingredient_id in available_products:
			if available_products[ingredient_id].count > 0:
				is_available = true
		
		if not is_available:
			return false
	
	return true

# Создание продукта через инструмент
func start_crafting(tool_instance_id: String, recipe_id: String) -> bool:
	if not can_craft_recipe(recipe_id):
		return false
	
	var product = available_products[recipe_id]
	var tool_data = available_tools[product.tool_id]
	
	# Собираем данные об ингредиентах для расчета качества
	var ingredients_quality = {}
	for ingredient_id in product.ingredients:
		if ingredient_id in available_ingredients:
			var ingredient = available_ingredients[ingredient_id]
			ingredients_quality[ingredient_id] = {
				"quality": ingredient.quality,
				"count": 1  # По одному для каждого типа
			}
			
			# Уменьшаем количество ингредиента
			ingredient.count -= 1
			emit_signal("product_count_changed", ingredient_id, ingredient.count, true)
		elif ingredient_id in available_products:
			var ingredient_product = available_products[ingredient_id]
			ingredients_quality[ingredient_id] = {
				"quality": ingredient_product.quality,
				"count": 1  # По одному для каждого типа
			}
			
			# Уменьшаем количество промежуточного продукта
			ingredient_product.count -= 1
			emit_signal("product_count_changed", ingredient_id, ingredient_product.count, false)
	
	# Рассчитываем качество результата
	var result_quality = calculate_result_quality(tool_data, ingredients_quality, product)
	
	# Создаем экземпляр инструмента для анимации процесса
	var tool_instance = get_tool_instance_by_id(tool_instance_id)
	if tool_instance:
		# Устанавливаем время обработки и результат
		tool_instance.set_processing_data(
			tool_data.processing_time,
			recipe_id,
			result_quality
		)
		
		# Запускаем процесс
		tool_instance.start_processing()
		return true
	
	# Если что-то пошло не так, сразу выдаем результат
	_on_crafting_completed(recipe_id, result_quality)
	return true

# Поиск экземпляра инструмента по ID
func get_tool_instance_by_id(instance_id: String) -> ToolInstance:
	var tool_instances = get_tree().get_nodes_in_group("tool_instances")
	for instance in tool_instances:
		if instance is ToolInstance and instance.instance_id == instance_id:
			return instance
	return null

# Обработчик завершения крафта
func _on_crafting_completed(recipe_id: String, quality: int) -> void:
	if recipe_id.is_empty():
		push_warning("ProductionManager: завершение крафта с пустым ID рецепта")
		return
	
	if recipe_id in available_products:
		var product = available_products[recipe_id]
		
		# Увеличиваем количество продукта
		product.count += 1
		
		# Устанавливаем качество только если оно выше текущего
		if quality > product.quality:
			product.quality = quality
		
		# Отмечаем рецепт как изученный, если еще не отмечен
		if not recipe_id in learned_recipes or not learned_recipes[recipe_id]:
			learned_recipes[recipe_id] = true
			emit_signal("recipe_learned", recipe_id)
		
		# Воспроизводим звук завершения крафта
		if audio_manager:
			audio_manager.play_sound("production_complete", AudioManager.SoundType.GAMEPLAY)
		
		# Оповещаем о создании продукта
		emit_signal("recipe_completed", recipe_id, quality)
		emit_signal("product_count_changed", recipe_id, product.count, false)
	else:
		push_warning("ProductionManager: продукт с ID '" + recipe_id + "' не найден при завершении крафта")

# Расчет качества результата на основе качества ингредиентов и инструмента
func calculate_result_quality(tool: ToolData, ingredients: Dictionary, product: ProductData) -> int:
	var total_weight = 0.0
	var quality_sum = 0.0
	
	# Учитываем качество инструмента
	if "tool" in tool.quality_weights:
		var tool_weight = tool.quality_weights["tool"]
		quality_sum += tool.quality * tool_weight
		total_weight += tool_weight
	
	# Учитываем качество каждого ингредиента
	for ingredient_id in ingredients:
		var ingredient_data = ingredients[ingredient_id]
		var ingredient_quality = ingredient_data["quality"]
		var ingredient_type = ""
		
		# Определяем тип ингредиента
		if ingredient_id in available_ingredients:
			ingredient_type = available_ingredients[ingredient_id].type
		elif ingredient_id in available_products:
			ingredient_type = available_products[ingredient_id].type
		
		# Учитываем вес этого типа ингредиента
		if ingredient_type in tool.quality_weights:
			var weight = tool.quality_weights[ingredient_type]
			quality_sum += ingredient_quality * weight
			total_weight += weight
	
	# Рассчитываем среднее качество
	var average_quality = 0
	if total_weight > 0:
		average_quality = round(quality_sum / total_weight)
	
	# Ограничиваем качество от 0 до 3
	return clampi(average_quality, 0, 3)

# Улучшение качества ингредиента
func improve_ingredient(ingredient_id: String) -> bool:
	if not ingredient_id in available_ingredients:
		return false
	
	var ingredient = available_ingredients[ingredient_id]
	
	# Проверяем, можно ли улучшить
	if ingredient.quality >= 3:  # Максимальное качество = 3 (0-3)
		return false
	
	# Рассчитываем стоимость улучшения (например, в 2 раза больше базовой цены)
	var improvement_cost = ingredient.get_current_price() * 2
	
	# Проверяем, достаточно ли денег
	if game_manager.money < improvement_cost:
		return false
	
	# Улучшаем качество
	ingredient.quality += 1
	
	# Списываем деньги
	game_manager.change_money(-improvement_cost, "Улучшение ингредиента: " + ingredient.name)
	
	# Отправляем сигнал об улучшении
	emit_signal("product_quality_improved", ingredient_id, ingredient.quality)
	
	# Воспроизводим звук улучшения
	if audio_manager:
		audio_manager.play_sound("money_loss", AudioManager.SoundType.UI)
	
	return true

# Улучшение качества инструмента
func improve_tool(tool_id: String) -> bool:
	if not tool_id in available_tools:
		return false
	
	var tool = available_tools[tool_id]
	
	# Проверяем, можно ли улучшить
	if tool.quality >= 3:  # Максимальное качество = 3 (0-3)
		return false
	
	# Рассчитываем стоимость улучшения
	var improvement_cost = tool.get_improvement_cost()
	
	# Проверяем, достаточно ли денег
	if game_manager.money < improvement_cost:
		return false
	
	# Улучшаем качество
	tool.quality += 1
	
	# Списываем деньги
	game_manager.change_money(-improvement_cost, "Улучшение инструмента: " + tool.name)
	
	# Отправляем сигнал об улучшении
	emit_signal("tool_quality_improved", tool_id, tool.quality)
	
	# Воспроизводим звук улучшения
	if audio_manager:
		audio_manager.play_sound("money_loss", AudioManager.SoundType.UI)
	
	return true

# Покупка ингредиента
func buy_ingredient(ingredient_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
		
	if not ingredient_id in available_ingredients:
		return false
	
	var ingredient = available_ingredients[ingredient_id]
	var total_cost = ingredient.get_current_price() * amount
	
	# Проверяем, достаточно ли денег
	if game_manager.money < total_cost:
		return false
	
	# Списываем деньги
	game_manager.change_money(-total_cost, "Покупка ингредиента: " + ingredient.name)
	
	# Увеличиваем количество
	ingredient.count += amount
	
	# Отправляем сигнал об изменении количества
	emit_signal("product_count_changed", ingredient_id, ingredient.count, true)
	
	# Воспроизводим звук покупки
	if audio_manager:
		audio_manager.play_sound("money_loss", AudioManager.SoundType.UI)
	
	return true

# Получение списка ингредиентов по типу производства
func get_ingredients_by_type(production_type: String) -> Array:
	var result = []
	
	for id in available_ingredients:
		var ingredient = available_ingredients[id]
		if ingredient.production_type == production_type or ingredient.production_type == "all":
			result.append(ingredient)
	
	return result

# Получение списка инструментов по типу производства
func get_tools_by_type(production_type: String) -> Array:
	var result = []
	
	for id in available_tools:
		var tool = available_tools[id]
		if tool.production_type == production_type:
			result.append(tool)
	
	return result

# Получение списка продуктов по типу производства
func get_products_by_type(production_type: String, only_final: bool = false) -> Array:
	var result = []
	
	for id in available_products:
		var product = available_products[id]
		if product.production_type == production_type:
			if only_final and not product.is_final:
				continue
			result.append(product)
	
	return result

# Интерфейс для SaveManager - получение данных для сохранения
func get_save_data() -> Dictionary:
	var ingredients_data = {}
	var tools_data = {}
	var products_data = {}
	
	# Сохраняем данные об ингредиентах
	for id in available_ingredients:
		ingredients_data[id] = {
			"count": available_ingredients[id].count,
			"quality": available_ingredients[id].quality
		}
	
	# Сохраняем данные об инструментах
	for id in available_tools:
		tools_data[id] = {
			"quality": available_tools[id].quality
		}
	
	# Сохраняем данные о продуктах
	for id in available_products:
		products_data[id] = {
			"count": available_products[id].count,
			"quality": available_products[id].quality
		}
	
	return {
		"ingredients": ingredients_data,
		"tools": tools_data,
		"products": products_data,
		"learned_recipes": learned_recipes
	}

# Интерфейс для SaveManager - загрузка данных из сохранения
func load_save_data(data: Dictionary) -> void:
	# Восстанавливаем данные ингредиентов
	if "ingredients" in data:
		for id in data.ingredients:
			if id in available_ingredients:
				available_ingredients[id].count = data.ingredients[id].get("count", 0)
				available_ingredients[id].quality = data.ingredients[id].get("quality", 0)
	
	# Восстанавливаем данные инструментов
	if "tools" in data:
		for id in data.tools:
			if id in available_tools:
				available_tools[id].quality = data.tools[id].get("quality", 0)
	
	# Восстанавливаем данные продуктов
	if "products" in data:
		for id in data.products:
			if id in available_products:
				available_products[id].count = data.products[id].get("count", 0)
				available_products[id].quality = data.products[id].get("quality", 0)
	
	# Восстанавливаем изученные рецепты
	if "learned_recipes" in data:
		learned_recipes = data.learned_recipes.duplicate()

	print("ProductionManager: Загрузка сохранения завершена")
