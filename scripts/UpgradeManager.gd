extends Node

# Текущие уровни улучшений для каждой категории
var current_levels = {
	"samogon": 1,  # Стартовый уровень самогоноварения (по ГДД)
	"beer": 0,
	"wine": 0,
	"garage": 1    # Стартовый уровень гаража
}

# Улучшения инструментов (id инструмента -> уровень)
var tool_levels = {}

# Сигналы
signal upgrade_purchased(category, level)
signal tool_upgraded(tool_id, level)

func _ready() -> void:
	# Инициализация начальных данных
	_initialize_tools()

func _initialize_tools() -> void:
	# Создаем записи для всех инструментов с начальным уровнем 0
	for category in ["samogon", "beer", "wine"]:
		if DataService.tools.has(category):
			for tool_data in DataService.tools[category]:
				var tool_id = tool_data.get("id", "")
				if tool_id != "":
					tool_levels[tool_id] = 0

func purchase_upgrade(category: String) -> bool:
	# Проверяем, можно ли купить улучшение
	if not can_purchase(category):
		return false
	
	# Получаем следующий уровень
	var next_level = current_levels[category] + 1
	
	# Находим данные улучшения
	var upgrade_data = _get_upgrade_data(category, next_level)
	if upgrade_data.is_empty():
		return false
	
	# Снимаем деньги
	var cost = upgrade_data.get("cost", 0)
	GlobalState.money -= cost
	
	# Обновляем уровень
	current_levels[category] = next_level
	
	# Применяем разблокировки и улучшения
	DataService.apply_upgrade(upgrade_data)
	
	# Уведомляем о покупке
	upgrade_purchased.emit(category, next_level)
	
	return true

func upgrade_tool(tool_id: String) -> bool:
	# Проверяем, существует ли инструмент
	if not tool_levels.has(tool_id):
		return false
	
	# Находим данные инструмента
	var tool_data = _get_tool_data(tool_id)
	if tool_data.is_empty():
		return false
	
	# Проверяем, не достигнут ли максимальный уровень
	var current_level = tool_levels[tool_id]
	var improvement_costs = tool_data.get("improvement_costs", [])
	
	if current_level >= improvement_costs.size():
		return false  # Максимальный уровень достигнут
	
	# Получаем стоимость улучшения
	var cost = improvement_costs[current_level]
	
	# Проверяем, достаточно ли денег
	if GlobalState.money < cost:
		return false
	
	# Снимаем деньги
	GlobalState.money -= cost
	
	# Увеличиваем уровень
	tool_levels[tool_id] = current_level + 1
	
	# Уведомляем об улучшении
	tool_upgraded.emit(tool_id, tool_levels[tool_id])
	
	return true

func can_purchase(category: String) -> bool:
	# Проверяем, существует ли категория
	if not current_levels.has(category):
		return false
	
	# Получаем данные следующего улучшения
	var next_level = current_levels[category] + 1
	var upgrade_data = _get_upgrade_data(category, next_level)
	
	if upgrade_data.is_empty():
		return false  # Нет следующего уровня
	
	# Проверяем, достаточно ли денег
	var cost = upgrade_data.get("cost", 0)
	return GlobalState.money >= cost

func can_upgrade_tool(tool_id: String) -> bool:
	# Проверяем, существует ли инструмент
	if not tool_levels.has(tool_id):
		return false
	
	# Находим данные инструмента
	var tool_data = _get_tool_data(tool_id)
	if tool_data.is_empty():
		return false
	
	# Проверяем, не достигнут ли максимальный уровень
	var current_level = tool_levels[tool_id]
	var improvement_costs = tool_data.get("improvement_costs", [])
	
	if current_level >= improvement_costs.size():
		return false  # Максимальный уровень достигнут
	
	# Получаем стоимость улучшения
	var cost = improvement_costs[current_level]
	
	# Проверяем, достаточно ли денег
	return GlobalState.money >= cost

func get_tool_level(tool_id: String) -> int:
	return tool_levels.get(tool_id, 0)

func _get_upgrade_data(category: String, level: int) -> Dictionary:
	# Получаем список улучшений для категории
	var category_upgrades = DataService.upgrades.get(category, [])
	
	# Ищем улучшение с нужным уровнем
	for upgrade in category_upgrades:
		if upgrade.get("level", 0) == level:
			return upgrade
	
	return {}

func _get_tool_data(tool_id: String) -> Dictionary:
	# Ищем инструмент во всех категориях
	for category in ["samogon", "beer", "wine"]:
		if DataService.tools.has(category):
			for tool_data in DataService.tools[category]:
				if tool_data.get("id", "") == tool_id:
					return tool_data
	
	return {}

# Сохранение и загрузка
func save_data() -> Dictionary:
	return {
		"levels": current_levels,
		"tools": tool_levels
	}

func load_data(data: Dictionary) -> void:
	if data.has("levels"):
		for category in data["levels"]:
			current_levels[category] = data["levels"][category]
	
	if data.has("tools"):
		for tool_id in data["tools"]:
			tool_levels[tool_id] = data["tools"][tool_id]
