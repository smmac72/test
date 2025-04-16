extends Node

signal new_order(order_data)

@onready var client_manager = ClientManager
@onready var data_service = DataService

var pending_orders := []

func generate_order():
	var unlocked = data_service.visible_recipes
	if unlocked.size() == 0:
		unlocked = ["moonshine"] # safe fallback
	var client = client_manager.get_suitable_client(unlocked)
	var product = client.get("preferred_products", [unlocked[0]])[randi()%len(client.get("preferred_products", unlocked))]
	# order parameters
	var order = {
		"client": client,
		"product_id": product,
		"required_quality": client.get("required_quality",0)
	}
	pending_orders.append(order)
	emit_signal("new_order", order)

func complete_order(order, sold_quality:int, price:int):
	pending_orders.erase(order)
	# adjust money+rep
	var rep_gain = max(1, int(price/50))
	GlobalState.money += price
	GlobalState.reputation += rep_gain
