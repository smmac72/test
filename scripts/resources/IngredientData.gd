class_name IngredientData
extends Resource

@export var id: String
@export var name: String
@export var type: String
@export var production_type: String
@export var description: String
@export var quality_prices: Array[int] = []
@export var sprite: String
@export var category: String
@export var count: int = 0
@export var quality: int = 0

static func from_dict(data: Dictionary) -> IngredientData:
	var ingredient = IngredientData.new()
	ingredient.id = data.get("id", "")
	ingredient.name = data.get("name", "")
	ingredient.type = data.get("type", "")
	ingredient.production_type = data.get("production_type", "")
	ingredient.description = data.get("description", "")
	ingredient.quality_prices = data.get("quality_prices", [0, 0, 0, 0])
	ingredient.sprite = data.get("sprite", "")
	ingredient.category = data.get("category", "")
	ingredient.count = data.get("starting_count", 0)
	ingredient.quality = 0  # Начальное качество всегда 0
	return ingredient

func get_current_price() -> int:
	if quality < quality_prices.size():
		return quality_prices[quality]
	return 0

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"type": type,
		"production_type": production_type,
		"description": description,
		"quality_prices": quality_prices,
		"sprite": sprite,
		"category": category,
		"count": count,
		"quality": quality
	}
