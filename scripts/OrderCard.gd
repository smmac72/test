extends Panel
class_name OrderCard

var order_data:Dictionary

func set_order(order:Dictionary):
	order_data = order
	$VBox/LabelClient.text = order["client"]["name"]
	$VBox/LabelProd.text = order["product_id"] + " ⭐≥" + str(order["required_quality"])
