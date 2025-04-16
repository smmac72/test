extends Panel
class_name UpgradeWindow

@onready var vbox := $VBox

func _ready() -> void:
	for prod in ["samogon", "beer", "wine"]:
		_add_row(prod)

func _add_row(prod_type: String) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = prod_type.capitalize()
	row.add_child(lbl)

	var btn := Button.new()
	btn.text = "Upgrade"
	btn.pressed.connect(_on_upgrade.bind(prod_type))
	row.add_child(btn)

	vbox.add_child(row)

func _on_upgrade(prod_type: String) -> void:
	if UpgradeManager.can_purchase(prod_type):
		UpgradeManager.purchase(prod_type)
