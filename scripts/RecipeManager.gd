extends Node

# Список изученных рецептов
var learned_recipes = []

# Сигналы
signal recipe_learned(recipe_id)

func _ready():
	# Загружаем базовые рецепты
	_load_initial_recipes()

func _load_initial_recipes():
	# Загружаем начальные рецепты (первый уровень самогоноварения)
	var basic_recipes = ["sugar_mash", "moonshine"]
	for recipe_id in basic_recipes:
		if not recipe_id in learned_recipes:
			learned_recipes.append(recipe_id)

func learn_recipe(recipe_id: String) -> bool:
	# Проверяем, не изучен ли рецепт уже
	if recipe_id in learned_recipes:
		return false
	
	# Проверяем существование рецепта
	var recipe = _find_recipe(recipe_id)
	if recipe.is_empty():
		return false
	
	# Добавляем рецепт в изученные
	learned_recipes.append(recipe_id)
	
	# Уведомляем об изучении рецепта
	recipe_learned.emit(recipe_id)
	
	return true

func is_recipe_learned(recipe_id: String) -> bool:
	return recipe_id in learned_recipes

func get_learned_recipes() -> Array:
	return learned_recipes.duplicate()

func get_recipe_info(recipe_id: String) -> Dictionary:
	# Возвращает информацию о рецепте
	var recipe = _find_recipe(recipe_id)
	
	if recipe.is_empty():
		return {}
	
	# Если рецепт не изучен, возвращаем только базовую информацию
	if not recipe_id in learned_recipes:
		return {
			"id": recipe_id,
			"name": recipe.get("name", "Неизвестный рецепт"),
			"production_type": recipe.get("production_type", ""),
			"learned": false
		}
	
	# Возвращаем полную информацию для изученных рецептов
	recipe["learned"] = true
	return recipe

func _find_recipe(recipe_id: String) -> Dictionary:
	# Ищем рецепт в промежуточных продуктах
	for recipe in DataService.recipes.get("intermediate_products", []):
		if recipe.get("id", "") == recipe_id:
			return recipe
	
	# Ищем рецепт в финальных продуктах
	for recipe in DataService.recipes.get("final_products", []):
		if recipe.get("id", "") == recipe_id:
			return recipe
	
	return {}

func get_recipes_by_category(production_type: String) -> Dictionary:
	# Возвращает рецепты, сгруппированные по категориям
	var result = {
		"final_products": [],
		"intermediate_products": []
	}
	
	# Добавляем изученные рецепты
	for recipe_type in ["final_products", "intermediate_products"]:
		for recipe in DataService.recipes.get(recipe_type, []):
			if recipe.get("production_type", "") == production_type:
				var recipe_id = recipe.get("id", "")
				if recipe_id in learned_recipes:
					var recipe_info = recipe.duplicate()
					recipe_info["learned"] = true
					result[recipe_type].append(recipe_info)
	
	return result

func get_ingredients_for_recipe(recipe_id: String) -> Array:
	# Возвращает массив ингредиентов для рецепта
	var recipe = _find_recipe(recipe_id)
	if recipe.is_empty() or not recipe_id in learned_recipes:
		return []
	
	var ingredient_ids = recipe.get("ingredients", [])
	var ingredients = []
	
	for id in ingredient_ids:
		var ingredient = DataService.find_item(id)
		if not ingredient.is_empty():
			ingredients.append(ingredient)
	
	return ingredients

func get_required_tool_for_recipe(recipe_id: String) -> Dictionary:
	# Возвращает инструмент, необходимый для рецепта
	var recipe = _find_recipe(recipe_id)
	if recipe.is_empty() or not recipe_id in learned_recipes:
		return {}
	
	var tool_id = recipe.get("tool_id", "")
	if tool_id == "":
		return {}
	
	return DataService.find_tool(tool_id)

# Сохранение и загрузка
func save_data() -> Dictionary:
	return {
		"learned_recipes": learned_recipes
	}

func load_data(data: Dictionary) -> void:
	if data.has("learned_recipes"):
		learned_recipes = data["learned_recipes"]
