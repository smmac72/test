extends Node

var customers = []

@onready var data_service = DataService

func _ready():
	var cust = data_service.customers
	customers = cust.get("poor", []) + cust.get("middle", []) + cust.get("rich", [])

func get_random_client():
	return customers[randi() % customers.size()]

func get_suitable_client(unlocked_products:Array) -> Dictionary:
	var candidates := []
	for c in customers:
		for p in c.get("preferred_products", []):
			if p in unlocked_products:
				candidates.append(c)
				break
	if candidates.size() == 0:
		return get_random_client()
	return candidates[randi() % candidates.size()]
