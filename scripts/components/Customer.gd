class_name Customer
extends Control

# Сигналы
signal customer_clicked(customer)
signal customer_leave_requested(customer, satisfied)

# Компоненты
@onready var visual: TextureRect = $Visual
@onready var bubble: Control = $Bubble
@onready var bubble_text: Label = $Bubble/BubbleText
@onready var timer: Timer = $Timer

# Данные клиента
var customer_id: String = ""
var customer_data: Dictionary = {}
var patience: float = 100.0  # 0-100, уменьшается со временем
var leave_timer: float = 60.0  # секунды до ухода

func _ready() -> void:
	# Подключаем сигналы
	connect("gui_input", _on_gui_input)
	timer.connect("timeout", _on_timer_timeout)
	
	# Запускаем таймер обновления
	timer.start()

# Настройка клиента
func setup(data: Dictionary) -> void:
	customer_data = data
	customer_id = data.get("customer_id", "")
	
	# Устанавливаем визуальные элементы в зависимости от категории клиента
	var category = data.get("category", 0)  # 0 = бедный, 1 = средний, 2 = богатый
	var visual_id = data.get("visual", "default")
	
	# Загружаем спрайт клиента
	var sprite_path = "res://assets/images/customers/" + visual_id + ".png"
	if ResourceLoader.exists(sprite_path):
		visual.texture = load(sprite_path)
	else:
		# Если спрайт не найден, используем заглушку соответствующую категории
		sprite_path = "res://assets/images/customers/default_" + str(category) + ".png"
		if ResourceLoader.exists(sprite_path):
			visual.texture = load(sprite_path)
		else:
			visual.texture = preload("res://assets/images/customers/default.png")
	
	# Устанавливаем текст запроса
	var request = data.get("request", {})
	bubble_text.text = request.get("description", "Здравствуйте!")
	
	# Устанавливаем терпение в зависимости от категории
	match category:
		0:  # Бедный
			patience = 100.0
			leave_timer = 45.0
		1:  # Средний
			patience = 80.0
			leave_timer = 60.0
		2:  # Богатый
			patience = 60.0
			leave_timer = 90.0

# Обработка ввода
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("customer_clicked", self)

# Обработчик таймера
func _on_timer_timeout() -> void:
	# Уменьшаем терпение и таймер ухода
	patience -= 1.0
	leave_timer -= 1.0
	
	# Обновляем внешний вид в зависимости от терпения
	update_visual_state()
	
	# Проверяем, пора ли клиенту уходить
	if patience <= 0 or leave_timer <= 0:
		emit_signal("customer_leave_requested", self, false)

# Обновление визуального состояния
func update_visual_state() -> void:
	# Меняем цвет пузыря и выражение лица в зависимости от терпения
	if patience > 70:
		bubble.modulate = Color(1, 1, 1)
	elif patience > 40:
		bubble.modulate = Color(1, 0.8, 0.8)
	else:
		bubble.modulate = Color(1, 0.6, 0.6)

# Получение прямоугольника для обнаружения столкновений
func get_customer_rect() -> Rect2:
	return Rect2(global_position, size)
