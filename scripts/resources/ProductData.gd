class_name ProductData
extends Resource

@export var id: String
@export var name: String
@export var type: String
@export var production_type: String
@export var description: String
@export var tool_id: String
@export var ingredients: Array
@export var sell_prices: Array
@export var sprite: String
@export var is_final: bool
@export var count: int = 0
@export var quality: int = 0

static func from_intermediate_dict(data: Dictionary) -> ProductData:
	var product = ProductData.new()
	product.id = data.get("id", "")
	product.name = data.get("name", "")
	product.type = data.get("type", "")
	product.production_type = data.get("production_type", "")
	product.description = data.get("description", "")
	product.tool_id = data.get("tool_id", "")
	product.ingredients = data.get("ingredients", [])
	product.sell_prices = []  # Нет цен продажи для промежуточных продуктов
	product.sprite = data.get("sprite", "")
	product.is_final = false
	product.count = 0
	product.quality = 0
	return product

static func from_final_dict(data: Dictionary) -> ProductData:
	var product = ProductData.new()
	product.id = data.get("id", "")
	product.name = data.get("name", "")
	product.type = data.get("type", "")
	product.production_type = data.get("production_type", "")
	product.description = data.get("description", "")
	product.tool_id = data.get("tool_id", "")
	product.ingredients = data.get("ingredients", [])
	product.sell_prices = data.get("sell_prices", [0, 0, 0, 0])
	product.sprite = data.get("sprite", "")
	product.is_final = true
	product.count = 0
	product.quality = 0
	return product

func get_current_price() -> int:
	if is_final and quality < sell_prices.size():
		return sell_prices[quality]
	return 0

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"type": type,
		"production_type": production_type,
		"description": description,
		"tool_id": tool_id,
		"ingredients": ingredients,
		"sell_prices": sell_prices,
		"sprite": sprite,
		"is_final": is_final,
		"count": count,
		"quality": quality
	}
