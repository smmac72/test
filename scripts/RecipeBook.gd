extends Panel
class_name RecipeBook

@onready var vbox: VBoxContainer = $Scroll/VBox
var learned: Set = {}

func learn(id: String) -> void:
	if id in learned: return
	learned.insert(id)
	_render()

func _ready(): _render()

func _render():
	vbox.free_children()
	for rec in DataService.recipes["final_products"]:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = rec.name
		row.add_child(lbl)
		if rec.id in learned:
			var icon := Button.new()
			icon.text = "?"
			icon.pressed.connect(_show_recipe.bind(rec))
			row.add_child(icon)
		vbox.add_child(row)

func _show_recipe(rec: Dictionary):
	var txt := "%s:\n%s" % [
		rec.name, ", ".join(rec.ingredients)]
	var popup := AcceptDialog.new()
	popup.dialog_text = txt
	add_child(popup)
	popup.popup_centered()
