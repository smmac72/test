extends Node
class_name ProductionManager

@onready var ing_row: HBoxContainer = $IngredientRow
@onready var grid:    GridContainer = $WorkGrid
@onready var slot_template: Panel   = $WorkGrid/SlotTemplate
@onready var tool_row : HBoxContainer = $ToolRow
@onready var tool_icon := preload("res://scenes/widgets/Card.tscn")   # временно

func _ready() -> void:
	_spawn_slots()
	_spawn_start_ing()
	#_spawn_tools()

#––– создание 16 пустых слотов ––––––––––––––––––––––––––––––––––
func _spawn_slots() -> void:
	for i in range(16):
		var slot := slot_template.duplicate() as Panel
		slot.visible = true
		grid.add_child(slot)

#––– стартовые ингредиенты ––––––––––––––––––––––––––––––––––––––
func _spawn_start_ing() -> void:
	for ing_id in DataService.visible_ingredients:
		_create_card(ing_id)
		
func _spawn_tools():
	for tool_id in DataService.visible_tools:
		var tdef := DataService.tools
		if tdef == null:
			continue
		var icon := tool_icon.instantiate() as Card
		icon.set_item({"name":tdef["name"],"sprite":"placeholder"})
		tool_row.add_child(icon)
		icon.gui_input.connect(_on_tool_clicked.bind(tdef))

func _on_tool_clicked(ev: InputEvent, tdef: Dictionary):
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var popup := preload("res://scenes/ToolPopup.tscn").instantiate() as ToolPopup
		add_child(popup)
		popup.position = get_viewport().size/2 - popup.size/2
		popup.setup(tdef)
		popup.finished.connect(_on_product_ready)

func _on_product_ready(prod: Dictionary):
	if prod.is_empty(): return
	_create_card(prod["id"])
		
func _create_card(ing_id: String) -> void:
	# Собираем единый список словарей ингредиентов
	var info: Array[Dictionary] = []  # явный тип
	for section in ["common", "samogon", "beer", "wine"]:
		if DataService.ingredients.has(section):
			info.append_array(DataService.ingredients[section])

	# Ищем нужный словарь
	var item: Dictionary = {}
	for d in info:
		if d.get("id", "") == ing_id:
			item = d
			break
	if item.is_empty():
		return  # не нашли

	# Placeholder‑карточка
	var card := ColorRect.new()
	card.color = Color(randf(), randf(), randf())  # случайный цвет
	card.custom_minimum_size = Vector2(48, 48)

	var lbl := Label.new()
	lbl.text = item.get("name", ing_id)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(lbl)

	ing_row.add_child(card)
