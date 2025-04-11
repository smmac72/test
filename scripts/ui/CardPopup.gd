class_name CardPopup
extends Panel

# Сигналы
signal buy_pressed(card_data, amount)
signal improve_pressed(card_data)
signal discard_pressed(card_data)
signal close_pressed

# Компоненты
@onready var title_label: Label = $TitleLabel
@onready var description_label: Label = $DescriptionLabel
@onready var quality_stars: HBoxContainer = $QualityStars
@onready var price_label: Label = $PriceLabel
@onready var count_label: Label = $CountLabel
@onready var buy_button: Button = $BuyButton
@onready var improve_button: Button = $ImproveButton
@onready var discard_button: Button = $DiscardButton
@onready var close_button: Button = $CloseButton
@onready var amount_spinbox: SpinBox = $AmountSpinBox
@onready var amount_label: Label = $AmountLabel

# Текущие данные
var current_data = null
var current_type: String = ""

func _ready() -> void:
	# Подключаем сигналы
	buy_button.connect("pressed", _on_buy_button_pressed)
	improve_button.connect("pressed", _on_improve_button_pressed)
	discard_button.connect("pressed", _on_discard_button_pressed)
	close_button.connect("pressed", _on_close_button_pressed)
	
	# Воспроизводим звук открытия
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("popup_open", AudioManager.SoundType.UI)

# Настройка попапа
func setup(data) -> void:
	current_data = data
	
	# Определяем тип данных
	if data is IngredientData:
		current_type = "ingredient"
	elif data is ToolData:
		current_type = "tool"
	elif data is ProductData:
		current_type = "product"
	
	# Обновляем содержимое
	update_content()

# Обновление содержимого
func update_content() -> void:
	if current_data == null:
		return
	
	# Заполняем основную информацию
	title_label.text = current_data.name
	description_label.text = current_data.description
	
	# Настраиваем звезды качества
	for i in range(quality_stars.get_child_count()):
		var star = quality_stars.get_child(i)
		star.visible = i < current_data.quality
	
	# Обрабатываем разные типы карточек
	match current_type:
		"ingredient":
			# Для ингредиентов
			price_label.text = "Цена: " + str(current_data.get_current_price()) + "₽"
			count_label.text = "В наличии: " + str(current_data.count)
			
			# Показываем кнопки и спинбокс для ингредиентов
			buy_button.visible = true
			improve_button.visible = current_data.quality < 3
			discard_button.visible = false
			amount_spinbox.visible = true
			amount_label.visible = true
			
			# Настраиваем спинбокс
			amount_spinbox.min_value = 1
			amount_spinbox.max_value = 10
			amount_spinbox.value = 1
		
		"tool":
			# Для инструментов
			var improvement_cost = current_data.get_improvement_cost()
			price_label.text = "Улучшение: " + str(improvement_cost) + "₽"
			count_label.text = ""
			
			# Показываем только кнопку улучшения
			buy_button.visible = false
			improve_button.visible = current_data.quality < 3
			discard_button.visible = false
			amount_spinbox.visible = false
			amount_label.visible = false
			
			# Проверяем, хватает ли денег на улучшение
			var game_manager = $"/root/GameManager"
			improve_button.disabled = game_manager.money < improvement_cost
		
		"product":
			# Для продуктов
			if current_data.is_final:
				price_label.text = "Цена продажи: " + str(current_data.get_current_price()) + "₽"
			else:
				price_label.text = "Промежуточный продукт"
			
			count_label.text = "В наличии: " + str(current_data.count)
			
			# Показываем только кнопку выбросить
			buy_button.visible = false
			improve_button.visible = false
			discard_button.visible = current_data.count > 0
			amount_spinbox.visible = false
			amount_label.visible = false

# Обработчики кнопок
func _on_buy_button_pressed() -> void:
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	if current_type == "ingredient":
		var amount = int(amount_spinbox.value)
		emit_signal("buy_pressed", current_data, amount)
		update_content()  # Обновляем содержимое после покупки

func _on_improve_button_pressed() -> void:
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	emit_signal("improve_pressed", current_data)
	update_content()  # Обновляем содержимое после улучшения

func _on_discard_button_pressed() -> void:
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	emit_signal("discard_pressed", current_data)
	update_content()  # Обновляем содержимое после выброса

func _on_close_button_pressed() -> void:
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("popup_close", AudioManager.SoundType.UI)
	
	emit_signal("close_pressed")
	hide()
