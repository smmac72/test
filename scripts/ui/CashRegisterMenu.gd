class_name CashRegisterMenu
extends Panel

# Сигналы
signal money_taken(amount)
signal closed

# Компоненты
@onready var current_money_label: Label = $CurrentMoneyLabel
@onready var amount_spinbox: SpinBox = $AmountSpinBox
@onready var take_button: Button = $TakeButton
@onready var close_button: Button = $CloseButton

# Текущие данные
var available_money: int = 0

func _ready() -> void:
	# Подключаем сигналы
	take_button.connect("pressed", _on_take_button_pressed)
	close_button.connect("pressed", _on_close_button_pressed)
	
	# Получаем текущее количество денег
	var game_manager = $"/root/GameManager"
	available_money = game_manager.money
	
	# Обновляем интерфейс
	update_ui()

# Обновление интерфейса
func update_ui() -> void:
	current_money_label.text = "В кассе: " + str(available_money) + "₽"
	
	# Настраиваем спинбокс
	amount_spinbox.min_value = 0
	amount_spinbox.max_value = available_money
	amount_spinbox.step = 10
	amount_spinbox.value = 0

# Показ попапа
func popup_centered() -> void:
	# Устанавливаем позицию
	var viewport_size = get_viewport_rect().size
	var panel_size = size
	position = (viewport_size - panel_size) / 2
	
	# Показываем
	show()

# Обработчик нажатия на кнопку взять
func _on_take_button_pressed() -> void:
	var amount = int(amount_spinbox.value)
	if amount > 0 and amount <= available_money:
		emit_signal("money_taken", amount)
		available_money -= amount
		update_ui()

# Обработчик нажатия на кнопку закрытия
func _on_close_button_pressed() -> void:
	emit_signal("closed")
	hide()
