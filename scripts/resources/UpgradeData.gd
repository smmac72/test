class_name UpgradeData
extends Resource

@export var id: String
@export var name: String
@export var description: String
@export var production_type: String
@export var level: int
@export var cost: int
@export var unlocks: Dictionary
@export var grid_size: Vector2i

static func from_dict(data: Dictionary) -> UpgradeData:
	var upgrade = UpgradeData.new()
	upgrade.id = data.get("id", "")
	upgrade.name = data.get("name", "")
	upgrade.description = data.get("description", "")
	upgrade.production_type = data.get("production_type", "")
	upgrade.level = data.get("level", 1)
	upgrade.cost = data.get("cost", 0)
	upgrade.unlocks = data.get("unlocks", {})
	
	if "grid_size" in data:
		upgrade.grid_size = Vector2i(
			data.grid_size.get("width", 5),
			data.grid_size.get("height", 3)
		)
	else:
		upgrade.grid_size = Vector2i(5, 3)
	
	return upgrade

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"production_type": production_type,
		"level": level,
		"cost": cost,
		"unlocks": unlocks,
		"grid_size": {
			"width": grid_size.x,
			"height": grid_size.y
		}
	}
