class_name CardData
extends Resource

# Базовый класс для данных карточек (ингредиенты, инструменты, продукты)

# Базовые свойства
@export var id: String
@export var name: String
@export var description: String
@export var sprite: String
@export var production_type: String

# Конвертация в словарь
func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"sprite": sprite,
		"production_type": production_type
	}

# Загрузка из словаря
func from_dictionary(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	sprite = data.get("sprite", "")
	production_type = data.get("production_type", "")

# Виртуальный метод для получения отображаемого типа
func get_display_type() -> String:
	return "Карточка"

# Виртуальный метод для получения цены
func get_price() -> int:
	return 0

# Проверка совместимости с другой карточкой
func is_compatible_with(other_card: CardData) -> bool:
	return false
