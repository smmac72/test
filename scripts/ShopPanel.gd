extends Panel
class_name ShopPanel

@onready var orders_vbox: VBoxContainer = $"OrdersScroll/OrdersVBox"
@onready var order_manager             = OrderManager

func _ready() -> void:
	order_manager.new_order.connect(_on_new_order)

func _on_new_order(order: Dictionary) -> void:
	var scene := preload("res://scenes/OrderCard.tscn")
	var card  := scene.instantiate()
	card.set_order(order)
	orders_vbox.add_child(card)

	# простая анимация появления
	card.self_modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(card, "self_modulate:a", 1.0, 0.4)
