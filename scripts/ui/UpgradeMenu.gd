class_name UpgradeMenu
extends Panel

# Сигналы
signal upgrade_selected(upgrade_id)
signal closed

# Компоненты
@onready var category_buttons: HBoxContainer = $VBoxContainer/CategoryButtons
@onready var upgrades_container: VBoxContainer = $VBoxContainer/ScrollContainer/UpgradesContainer
@onready var close_button: Button = $CloseButton

# Текущие данные
var current_category: String = "samogon"
var available_upgrades: Dictionary = {}

func _ready() -> void:
	# Подключаем сигналы
	close_button.connect("pressed", _on_close_button_pressed)
	
	# Подключаем кнопки категорий
	for button in category_buttons.get_children():
		if button is Button:
			button.connect("pressed", _on_category_button_pressed.bind(button.name.to_lower()))
	
	# Загружаем доступные улучшения
	load_available_upgrades()
	
	# Воспроизводим звук открытия
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("popup_open", AudioManager.SoundType.UI)

# Загрузка доступных улучшений
func load_available_upgrades() -> void:
	# Получаем менеджеры
	var config_manager = $"/root/ConfigM"
	var game_manager = $"/root/GM"
	
	# Загружаем текущие уровни производства
	var production_levels = game_manager.production_levels
	
	# Загружаем все улучшения
	available_upgrades = {}
	
	for category in config_manager.upgrades:
		available_upgrades[category] = {}
		
		# Текущий уровень категории
		var current_level = production_levels.get(category, 0)
		
		# Следующий доступный уровень
		var next_level = current_level + 1
		
		# Если есть улучшение для следующего уровня, добавляем его
		if next_level in config_manager.upgrades[category]:
			available_upgrades[category][next_level] = config_manager.upgrades[category][next_level]
	
	# Загружаем улучшения для текущей категории
	load_upgrades_for_category(current_category)

# Загрузка улучшений для категории
func load_upgrades_for_category(category: String) -> void:
	# Очищаем контейнер
	for child in upgrades_container.get_children():
		child.queue_free()
	
	# Получаем доступные улучшения для категории
	if not category in available_upgrades or available_upgrades[category].size() == 0:
		# Если нет доступных улучшений, показываем сообщение
		var label = Label.new()
		label.text = "Нет доступных улучшений для этой категории"
		upgrades_container.add_child(label)
		return
	
	# Добавляем улучшения в контейнер
	for level in available_upgrades[category]:
		var upgrade_data = available_upgrades[category][level]
		var upgrade_item = preload("res://scenes/ui/UpgradeItem.tscn").instantiate()
		upgrade_item.setup(upgrade_data)
		upgrade_item.connect("upgrade_clicked", _on_upgrade_clicked)
		upgrades_container.add_child(upgrade_item)

# Фильтрация по типу производства
func filter_by_type(production_type: String) -> void:
	current_category = production_type
	
	# Обновляем выбранную категорию
	for button in category_buttons.get_children():
		if button is Button:
			var category = button.name.to_lower()
			button.button_pressed = (category == production_type)
	
	# Загружаем улучшения
	load_upgrades_for_category(production_type)

# Показ меню по центру экрана
func popup_centered() -> void:
	# Центрируем панель на экране
	var viewport_size = get_viewport_rect().size
	var panel_size = size
	position = (viewport_size - panel_size) / 2
	
	# Показываем панель
	show()

# Обработчик нажатия на кнопку категории
func _on_category_button_pressed(category: String) -> void:
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	current_category = category
	load_upgrades_for_category(category)

# Обработчик нажатия на улучшение
func _on_upgrade_clicked(upgrade_id: String) -> void:
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	emit_signal("upgrade_selected", upgrade_id)
	hide()

# Обработчик нажатия на кнопку закрытия
func _on_close_button_pressed() -> void:
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("popup_close", AudioManager.SoundType.UI)
	
	emit_signal("closed")
	hide()
