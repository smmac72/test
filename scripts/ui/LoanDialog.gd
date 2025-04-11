class_name LoanDialog
extends Panel

# Сигналы
signal loan_accepted(amount)
signal loan_rejected

# Компоненты
@onready var title_label: Label = $TitleLabel
@onready var description_label: Label = $DescriptionLabel
@onready var amount_label: Label = $AmountLabel
@onready var interest_label: Label = $InterestLabel
@onready var due_date_label: Label = $DueDateLabel
@onready var accept_button: Button = $AcceptButton
@onready var reject_button: Button = $RejectButton

# Данные займа
var loan_amount: int = 0
var loan_reason: String = ""
var loan_duration: int = 7  # 7 дней
var loan_interest: float = 0.1  # 10% за весь срок

func _ready() -> void:
	# Подключаем сигналы кнопок
	accept_button.connect("pressed", _on_accept_button_pressed)
	reject_button.connect("pressed", _on_reject_button_pressed)

# Настройка диалога
func setup(amount: int, reason: String = "") -> void:
	loan_amount = amount
	loan_reason = reason
	
	# Заполняем данные
	title_label.text = "Предложение займа"
	description_label.text = loan_reason if loan_reason else "Вам предлагают взять займ для покрытия расходов."
	amount_label.text = "Сумма: " + str(loan_amount) + "₽"
	
	# Рассчитываем проценты
	var interest_amount = int(loan_amount * loan_interest)
	interest_label.text = "Проценты: " + str(interest_amount) + "₽ (" + str(int(loan_interest * 100)) + "%)"
	
	# Получаем дату погашения
	var game_manager = $"/root/GameManager"
	var due_day = game_manager.game_day + loan_duration
	due_date_label.text = "Срок погашения: День " + str(due_day)

# Обработчики кнопок
func _on_accept_button_pressed() -> void:
	emit_signal("loan_accepted", loan_amount)
	queue_free()

func _on_reject_button_pressed() -> void:
	emit_signal("loan_rejected")
	queue_free()

# Показ диалога
func popup_centered() -> void:
	# Центрируем диалог
	var viewport_size = get_viewport_rect().size
	var panel_size = size
	position = (viewport_size - panel_size) / 2
	
	# Показываем
	show()
