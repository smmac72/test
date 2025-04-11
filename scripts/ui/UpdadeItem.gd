class_name UpgradeItem
extends Control

# Сигналы
signal upgrade_clicked(upgrade_id)

# Компоненты
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel
@onready var unlock_list: Label = $VBoxContainer/UnlockList
@onready var buy_button: Button = $VBoxContainer/BuyButton

# Данные улучшения
var upgrade_data: Dictionary = {}

func _ready() -> void:
	# Подключаем сигнал кнопки
	buy_button.connect("pressed", _on_buy_button_pressed)

# Настройка элемента улучшения
func setup(data: Dictionary) -> void:
	upgrade_data = data
	
	# Заполняем данные
	name_label.text = data.get("name", "Улучшение")
	description_label.text = data.get("description", "")
	cost_label.text = "Стоимость: " + str(data.get("cost", 0)) + "₽"
	
	# Формируем список того, что открывает улучшение
	var unlocks = data.get("unlocks", {})
	var unlock_text = "Открывает:"
	
	if "tools" in unlocks and unlocks["tools"].size() > 0:
		unlock_text += "\n- Инструменты: " + str(unlocks["tools"].size())
	
	if "ingredients" in unlocks and unlocks["ingredients"].size() > 0:
		unlock_text += "\n- Ингредиенты: " + str(unlocks["ingredients"].size())
	
	if "recipes" in unlocks and unlocks["recipes"].size() > 0:
		unlock_text += "\n- Рецепты: " + str(unlocks["recipes"].size())
	
	unlock_list.text = unlock_text
	
	# Проверяем, хватает ли денег для покупки
	check_availability()

# Проверка доступности улучшения
func check_availability() -> void:
	var game_manager = $"/root/GameManager"
	var cost = upgrade_data.get("cost", 0)
	
	if game_manager.money < cost:
		buy_button.disabled = true
		buy_button.text = "Недостаточно денег"
	else:
		buy_button.disabled = false
		buy_button.text = "Купить"

# Обработчик кнопки покупки
func _on_buy_button_pressed() -> void:
	emit_signal("upgrade_clicked", upgrade_data.get("id", ""))
