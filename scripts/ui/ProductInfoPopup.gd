class_name ProductInfoPopup
extends Panel

# Сигналы
signal price_changed(new_modifier)
signal discard_pressed
signal closed

# Компоненты
@onready var title_label: Label = $TitleLabel
@onready var description_label: Label = $DescriptionLabel
@onready var quality_stars: HBoxContainer = $QualityStars
@onready var base_price_label: Label = $BasePriceLabel
@onready var final_price_label: Label = $FinalPriceLabel
@onready var price_slider: HSlider = $PriceSlider
@onready var discard_button: Button = $DiscardButton
@onready var close_button: Button = $CloseButton

# Данные продукта
var product_data: ProductData
var price_modifier: float = 1.0
var base_price: int = 0

func _ready() -> void:
	# Подключаем сигналы
	price_slider.connect("value_changed", _on_price_slider_changed)
	discard_button.connect("pressed", _on_discard_button_pressed)
	close_button.connect("pressed", _on_close_button_pressed)

# Настройка попапа
func setup(data: ProductData, modifier: float = 1.0) -> void:
	product_data = data
	price_modifier = modifier
	
	# Заполняем данные
	title_label.text = data.name
	description_label.text = data.description
	
	# Устанавливаем звезды качества
	for i in range(quality_stars.get_child_count()):
		var star = quality_stars.get_child(i)
		star.visible = i < data.quality
	
	# Устанавливаем базовую цену
	base_price = data.get_current_price()
	base_price_label.text = "Базовая цена: " + str(base_price) + "₽"
	
	# Настраиваем слайдер цены
	price_slider.min_value = 0.5
	price_slider.max_value = 2.0
	price_slider.step = 0.05
	price_slider.value = price_modifier
	
	# Обновляем отображение итоговой цены
	update_final_price()

# Обновление итоговой цены
func update_final_price() -> void:
	var final_price = int(base_price * price_modifier)
	final_price_label.text = "Цена продажи: " + str(final_price) + "₽"
	
	# Меняем цвет текста в зависимости от модификатора
	if price_modifier < 1.0:
		final_price_label.modulate = Color(0.5, 0.8, 1.0)  # Синий (скидка)
	elif price_modifier > 1.0:
		final_price_label.modulate = Color(1.0, 0.7, 0.7)  # Красный (наценка)
	else:
		final_price_label.modulate = Color(1.0, 1.0, 1.0)  # Белый (стандартная цена)

# Показать попап
func popup_centered() -> void:
	# Устанавливаем позицию
	var viewport_size = get_viewport_rect().size
	var panel_size = size
	position = (viewport_size - panel_size) / 2
	
	# Показываем
	show()

# Обработчик изменения слайдера цены
func _on_price_slider_changed(value: float) -> void:
	price_modifier = value
	update_final_price()
	emit_signal("price_changed", price_modifier)

# Обработчик нажатия на кнопку выбросить
func _on_discard_button_pressed() -> void:
	emit_signal("discard_pressed")
	hide()

# Обработчик нажатия на кнопку закрытия
func _on_close_button_pressed() -> void:
	emit_signal("closed")
	hide()
