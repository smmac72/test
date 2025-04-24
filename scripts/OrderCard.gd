extends Panel
class_name OrderCard

# Данные заказа
var order_data: Dictionary = {}

# Компоненты UI
@onready var client_label: Label = $VBox/HBoxTop/LabelClient
@onready var client_icon: TextureRect = $VBox/HBoxTop/ClientIcon
@onready var product_label: Label = $VBox/LabelProd
@onready var quality_label: Label = $VBox/LabelQuality
@onready var soundCllick = $UiClick
# Настройки отображения
var original_modulate: Color

# Сигналы
signal order_clicked(order_card)

func _ready():
	soundCllick.bus = "&Sfx"
	# Запоминаем исходный цвет для восстановления
	original_modulate = modulate
	
	# Скрываем ненужные элементы для упрощенной версии
	if has_node("VBox/LabelTime"):
		$VBox/LabelTime.visible = false
	if has_node("VBox/ProgressBar"):
		$VBox/ProgressBar.visible = false
	if has_node("Timer"):
		$Timer.stop()
		$Timer.queue_free()
	
	# Подключаем сигналы мыши
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_order(order: Dictionary):
	# Сохраняем данные заказа
	order_data = order
	
	# Заполняем информацию о клиенте
	var client = order.get("client", {})
	client_label.text = client.get("name", "Клиент")
	
	# Пытаемся загрузить иконку клиента
	var visual_key = client.get("visual", "client_placeholder")
	var texture_path = "res://art/clients/%s.png" % visual_key
	if ResourceLoader.exists(texture_path):
		client_icon.texture = load(texture_path)
	
	# Информация о продукте
	var product_id = order.get("product_id", "")
	var product_info = DataService.find_item(product_id)
	product_label.text = product_info.get("name", product_id)
	
	# Требуемое качество
	var req_quality = order.get("required_quality", 0)
	quality_label.text = "Качество: " + "⭐".repeat(req_quality + 1)

func _on_mouse_entered():
	# Подсветка при наведении
	modulate = original_modulate.lightened(0.2)

func _on_mouse_exited():
	# Возврат обычного цвета при уходе мыши
	modulate = original_modulate

func _gui_input(event):
	# Обработка нажатия на карточку
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		soundCllick.play()
		order_clicked.emit(self)
