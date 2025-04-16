extends Panel
class_name Tool

@export var tool_id : String
@export var processing_time : int = 10
var recipe : Dictionary
var slots := {}
var is_running := false

@onready var timer := get_node("Timer")

func _ready():
	timer.wait_time = processing_time
	timer.timeout.connect(_on_done)

func can_start() -> bool:
	if is_running:
		return false
	# check all required slots filled
	for s in slots.values():
		if s.get("required", false) and s["node"].contained_card == null:
			return false
	return true

func start():
	if not can_start():
		return
	is_running = true
	timer.start()

func _on_done():
	is_running = false
	# produce output card based on recipe
	var output = _calculate_output()
	emit_signal("tool_finished", output)
	# clear slots
	for s in slots.values():
		if s["node"].contained_card:
			s["node"].contained_card.queue_free()
			s["node"].contained_card = null

func _calculate_output():
	# simplistic: choose first recipe that matches
	for rec in DataService.recipes.get("final_products", []):
		if rec["tool_id"] == tool_id:
			# check ingredients match types
			var types_needed = rec["ingredients"]
			var ids := []
			for s in slots.values():
				if s["node"].contained_card:
					ids.append(s["node"].contained_card.item_data["id"])
			var ok := true
			for need in types_needed:
				if need not in ids:
					ok = false
					break
			if ok:
				return rec
	return null
