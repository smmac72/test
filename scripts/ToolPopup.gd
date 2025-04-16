extends Panel
class_name ToolPopup

var tool_def: Dictionary          # из tools.json
var slots := []                   # Array[Slot]
signal finished(product: Dictionary)

@onready var grid  : GridContainer = $Grid
@onready var start : Button        = $BtnStart
@onready var timer : Timer         = $Timer
@onready var slot_template: Panel  = $Grid/SlotTemplate

func setup(tool: Dictionary) -> void:
	tool_def = tool
	_build_slots()
	start.pressed.connect(_on_start)

func _build_slots() -> void:
	for conf in tool_def["slots"]:
		var slot := slot_template.duplicate() as Slot
		slot.visible = true
		slot.accepted_type = conf["type"]
		slot.required      = conf["required"]
		grid.add_child(slot)
		slots.append(slot)

func _on_start() -> void:
	if not _all_required(): return
	start.disabled = true
	timer.wait_time = tool_def["processing_time"]
	timer.timeout.connect(_on_done, CONNECT_ONE_SHOT)
	timer.start()

func _all_required() -> bool:
	for s in slots:
		if s.required and s.contained_card == null:
			return false
	return true

func _on_done() -> void:
	var prod := _produce()
	finished.emit(prod)
	queue_free()

func _produce() -> Dictionary:
	# собираем id карт
	var ids: Array[String] = []
	for s in slots:
		if s.contained_card:
			ids.append(s.contained_card.item_data["id"])

	# ищем рецепт
	for rec in DataService.recipes["final_products"]:
		if rec["tool_id"] == tool_def["id"] and _match(rec["ingredients"], ids):
			rec["quality"] = _quality(rec, ids)
			return rec
	return {}

func _match(need: Array, have: Array) -> bool:
	for n in need:
		if n not in have:
			return false
	return true

func _quality(rec: Dictionary, ids: Array) -> int:
	var weights: Dictionary = tool_def["quality_weights"]
	var total_w := 0; var accum := 0
	for id in ids:
		var info := DataService.find_item(id)
		var q    := info.get("quality", 0) as float
		var w    := weights.get(info["type"], 10) as float
		accum  += q * w
		total_w += w
	accum +=  tool_def.get("upgrade_level",0) * 5  # бонус инструмента
	return roundi(accum / total_w)
