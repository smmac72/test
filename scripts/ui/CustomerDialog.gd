class_name CustomerDialog
extends Panel

# Сигналы
signal dialog_completed(result)

# Компоненты
@onready var customer_name: Label = $NameLabel
@onready var request_text: Label = $RequestLabel
@onready var response_options: VBoxContainer = $ResponseOptions
@onready var close_button: Button = $CloseButton

# Данные клиента
var customer_data: Dictionary = {}

func _ready() -> void:
	# Подключаем сигналы
	close_button.connect("pressed", _on_close_button_pressed)

# Настройка диалога
func setup(data: Dictionary) -> void:
	customer_data = data
	
	# Заполняем информацию
	customer_name.text = data.get("name", "Клиент")
	
	# Получаем информацию о запросе
	var request = data.get("request", {})
	var request_type = request.get("type", "")
	var product_id = request.get("product_id", "")
	var required_quality = request.get("required_quality", 0)
	var max_price = request.get("max_price", 0)
	
	# Формируем текст запроса
	var text = request.get("description", "Здравствуйте!")
	
	if request_type == "specific":
		# Добавляем информацию о качестве, если требуется
		if required_quality > 0:
			text += "\nМне нужно качество не ниже " + str(required_quality) + " звезд."
		
		# Добавляем информацию о цене
		if max_price > 0:
			text += "\nЯ готов заплатить до " + str(max_price) + "₽."
	else:
		text += "\nПосоветуйте что-нибудь хорошее."
	
	request_text.text = text
	
	# Добавляем варианты ответов
	create_response_options()

# Создание вариантов ответов
func create_response_options() -> void:
	# Очищаем контейнер
	for child in response_options.get_children():
		child.queue_free()
	
	# Добавляем стандартные варианты ответов
	var options = [
		"Сейчас подберу для вас что-нибудь подходящее.",
		"У нас как раз есть то, что вам нужно!",
		"Давайте я покажу вам наш ассортимент."
	]
	
	for option_text in options:
		var button = Button.new()
		button.text = option_text
		button.connect("pressed", _on_option_selected.bind(option_text))
		response_options.add_child(button)

# Обработчик выбора варианта ответа
func _on_option_selected(option: String) -> void:
	# Здесь можно добавить логику для разных ответов
	emit_signal("dialog_completed", {"response": option})
	hide()

# Обработчик нажатия на кнопку закрытия
func _on_close_button_pressed() -> void:
	emit_signal("dialog_completed", {"response": "close"})
	hide()
