extends Node

var upgrades_by_prod = {}
var current_levels = {}

func _ready():
	upgrades_by_prod = DataService.upgrades
	for p in upgrades_by_prod.keys():
		current_levels[p] = 0

func can_purchase(prod_type:String) -> bool:
	var next_level = current_levels[prod_type] + 1
	var list = upgrades_by_prod.get(prod_type, [])
	for up in list:
		if up["level"] == next_level:
			return GlobalState.money >= up["cost"]
	return false

func purchase(prod_type:String):
	var next_level = current_levels[prod_type] + 1
	var list = upgrades_by_prod.get(prod_type, [])
	for up in list:
		if up["level"] == next_level:
			if GlobalState.money >= up["cost"]:
				GlobalState.money -= up["cost"]
				current_levels[prod_type] = next_level
				# unlock stuff...
				DataService.apply_upgrade(up)
				print("Upgrade purchased", up["name"])
