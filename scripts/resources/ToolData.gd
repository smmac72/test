class_name ToolData
extends Resource

@export var id: String
@export var name: String
@export var description: String
@export var production_type: String
@export var slots: Array
@export var processing_time: float
@export var quality_weights: Dictionary
@export var improvement_costs: Array
@export var sprite: String
@export var category: String
@export var quality: int = 0

static func from_dict(data: Dictionary) -> ToolData:
	var tool = ToolData.new()
	tool.id = data.get("id", "")
	tool.name = data.get("name", "")
	tool.description = data.get("description", "")
	tool.production_type = data.get("production_type", "")
	tool.slots = data.get("slots", [])
	tool.processing_time = data.get("processing_time", 1.0)
	tool.quality_weights = data.get("quality_weights", {})
	tool.improvement_costs = data.get("improvement_costs", [])
	tool.sprite = data.get("sprite", "")
	tool.category = data.get("category", "")
	tool.quality = 0
	return tool

func get_improvement_cost() -> int:
	if quality < improvement_costs.size():
		return improvement_costs[quality]
	return 0

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"production_type": production_type,
		"slots": slots,
		"processing_time": processing_time,
		"quality_weights": quality_weights,
		"improvement_costs": improvement_costs,
		"sprite": sprite,
		"category": category,
		"quality": quality
	}
