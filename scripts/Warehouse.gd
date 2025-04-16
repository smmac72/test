extends Node
class_name Warehouse

var stock: Dictionary = {}           # id → count

func add(id: String, n:=1):
	stock[id] = stock.get(id, 0) + n

func take(id: String, n:=1) -> bool:
	if stock.get(id,0) < n: return false
	stock[id] -= n
	return true

func count(id: String) -> int:
	return stock.get(id,0)
