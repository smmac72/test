class_name ToolSlot
extends Control

# Сигналы
signal item_dropped(slot_id, item_data)
signal item_removed(slot_id)

# Свойства
@export var slot_id: String = ""
@export var slot_type: String = ""
@export var required: bool = true
@export var display_name: String = ""

# Состояние слота
var content = null

# Компоненты
@onready var background: Panel = $Background
@onready var content_icon: TextureRect = $ContentIcon
@onready var type_label: Label = $TypeLabel
@onready var required_indicator: TextureRect = $RequiredIndicator

func _ready() -> void:
	# Настройка отображения
	type_label.text = display_name
	required_indicator.visible = required
	
	# Начальное состояние
	content_icon.visible = false
	
	# Подключение к сигналам
	connect("gui_input", _on_gui_input)

# Обновление визуального представления
func update_visual(item_data) -> void:
	content = item_data
	
	if content == null:
		content_icon.visible = false
		background.modulate = Color(1, 1, 1, 0.5)
	else:
		# Устанавливаем иконку в зависимости от типа предмета
		content_icon.visible = true
		
		var sprite_path = ""
		if content is IngredientData:
			sprite_path = "res://assets/images/ingredients/" + content.sprite + ".png"
		elif content is ProductData:
			sprite_path = "res://assets/images/products/" + content.sprite + ".png"
		
		if ResourceLoader.exists(sprite_path):
			content_icon.texture = load(sprite_path)
		else:
			content_icon.texture = preload("res://assets/images/default.png")
		
		background.modulate = Color(1, 1, 1, 1)

# Получение ID слота
func get_slot_id() -> String:
	return slot_id

# Проверка занятости слота
func is_occupied() -> bool:
	return content != null

# Обработчик ввода
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Правый клик для удаления предмета
			if content != null:
				emit_signal("item_removed", slot_id)
				
				# Воспроизводим звук
				var audio_manager = $"/root/AudioManager"
				if audio_manager:
					audio_manager.play_sound("item_pickup", AudioManager.SoundType.GAMEPLAY)

# Проверка совместимости предмета со слотом
func can_accept_item(item_data) -> bool:
	if content != null:
		return false
	
	var item_type = ""
	if item_data is IngredientData:
		item_type = item_data.type
	elif item_data is ProductData:
		item_type = item_data.type
	
	return slot_type == item_type

# Обработка сброса предмета
func handle_item_drop(item_data) -> bool:
	if can_accept_item(item_data):
		emit_signal("item_dropped", slot_id, item_data)
		
		# Воспроизводим звук
		var audio_manager = $"/root/AudioManager"
		if audio_manager:
			audio_manager.play_sound("item_place", AudioManager.SoundType.GAMEPLAY)
		
		return true
	return false

func highlight_as_available() -> void:
	# Change the visual appearance to show this slot can accept an item
	modulate = Color(0.8, 1.0, 0.8)  # Light green glow

func reset_highlighting() -> void:
	# Reset to normal appearance
	modulate = Color(1, 1, 1)  # Normal color
