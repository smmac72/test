class_name EventDialog
extends Panel

# Сигналы
signal option_selected(option_id)

# Компоненты
@onready var title_label: Label = $TitleLabel
@onready var description_label: Label = $DescriptionLabel
@onready var event_image: TextureRect = $EventImage
@onready var options_container: VBoxContainer = $OptionsContainer

# Данные события
var event_data: Dictionary = {}

func _ready() -> void:
	# Настраиваем внешний вид
	var style = get_theme_stylebox("panel", "Panel").duplicate()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	add_theme_stylebox_override("panel", style)

# Настройка диалога
func setup(data: Dictionary) -> void:
	return
	event_data = data
	
	# Заполняем данные
	title_label.text = data.get("name", "Событие")
	description_label.text = get_event_description(data)
	
	# Устанавливаем изображение события
	var type = data.get("type", 0)
	var image_path = "res://assets/images/events/"
	
	match type:
		0:  # POLICE
			image_path += "police.png"
		1:  # CRIMINAL
			image_path += "criminal.png"
		2:  # VIP_CLIENT
			image_path += "vip_client.png"
		3:  # UTILITY_PAYMENT
			image_path += "utility.png"
		_:  # DEFAULT or RANDOM
			image_path += "random_event.png"
	
	if ResourceLoader.exists(image_path):
		event_image.texture = load(image_path)
	
	# Создаем кнопки для опций
	create_option_buttons(data.get("options", []))

# Получение описания события
func get_event_description(data: Dictionary) -> String:
	var type = data.get("type", 0)
	
	# Особая обработка для платежа
	if type == 3:  # UTILITY_PAYMENT
		return "Пришло время оплатить коммунальные услуги.\nСумма к оплате: " + str(data.get("payment_amount", 0)) + "₽"
	
	# Для остальных типов возвращаем стандартное описание
	return data.get("description", "")

# Создание кнопок опций
func create_option_buttons(options: Array) -> void:
	# Очищаем контейнер
	for child in options_container.get_children():
		child.queue_free()
	
	# Создаем кнопки для каждой опции
	for option in options:
		var button = Button.new()
		button.text = option.get("text", "Опция")
		button.connect("pressed", _on_option_button_pressed.bind(option.get("id", "")))
		
		# Проверяем доступность опции
		var requirements = option.get("requirements", {})
		var is_available = true
		
		# Проверка требования по деньгам
		if "money" in requirements:
			var required_money = requirements["money"]
			var game_manager = $"/root/GameManager"
			if game_manager.money < required_money:
				is_available = false
				button.disabled = true
				button.text += " (недостаточно денег)"
		
		options_container.add_child(button)

# Обработчик нажатия на кнопку опции
func _on_option_button_pressed(option_id: String) -> void:
	emit_signal("option_selected", option_id)
	hide()

# Показ диалога
func popup_centered() -> void:
	# Центрируем диалог
	var viewport_size = get_viewport_rect().size
	var panel_size = size
	position = (viewport_size - panel_size) / 2
	
	# Показываем
	show()
