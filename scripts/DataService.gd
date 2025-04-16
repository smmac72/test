extends Node

var ingredients := {}
var recipes     := {}
var tools       := {}
var customers   := {}
var upgrades    := {}      # ← новое свойство

# «видимость» контента после апгрейдов
var visible_ingredients : Array[String] = []
var visible_tools       : Array[String] = []
var visible_recipes     : Array[String] = []

func _ready() -> void:
	_load_json("res://data/ingredients.json", ingredients)
	_load_json("res://data/recipes.json",     recipes)
	_load_json("res://data/customers.json",   customers)
	_load_json("res://data/upgrades.json",    upgrades)
	_load_json("res://data/tools.json", tools)
	
	# по умолчанию показываем только то, что открыто на старте
	visible_recipes  = ["moonshine"]
	visible_tools    = ["fermentation", "distiller"]
	visible_ingredients = ["water", "sugar", "koji"]

func _load_json(path: String, target: Dictionary) -> void:
	if not ResourceLoader.exists(path):
		push_error("%s not found" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var txt: String = file.get_as_text()
		var parsed: Variant = JSON.parse_string(txt)
		if parsed is Dictionary:
			target.merge(parsed as Dictionary, true)

# вызывается UpgradeManager после покупки
func apply_upgrade(data: Dictionary) -> void:
	if data.has("unlocks"):
		var u: Dictionary = data["unlocks"]
		if u.has("ingredients"):
			visible_ingredients.append_array(u["ingredients"])
		if u.has("tools"):
			visible_tools.append_array(u["tools"])
		if u.has("recipes"):
			visible_recipes.append_array(u["recipes"])

func find_item(id:String) -> Dictionary:
	for section in ingredients.values():
		for d in section:
			if d.get("id","") == id:
				return d
	for d in recipes["intermediate_products"]:
		if d.id == id: return d
	return {}
