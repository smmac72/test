extends Panel
class_name UpgradeWindow

@onready var vbox: VBoxContainer = $VBox
@onready var close_btn: Button = $Close
@onready var upgrade_sound = $Upgrade
# Словарь для отображения информации о категориях улучшений
var upgrade_categories = {
	"samogon": "Производство самогона",
	"beer": "Производство пива",
	"wine": "Производство вина",
	"garage": "Гараж (рабочая зона)"
}

# Сигналы
signal upgrade_purchased(category, level)

func _ready() -> void:
	
	upgrade_sound.bus="&Sfx"
	# Подключаем сигнал кнопки закрытия
	close_btn.pressed.connect(_on_close)
	
	# Создаем интерфейс
	_initialize_ui()

func _initialize_ui() -> void:
	# Очищаем содержимое
	for child in vbox.get_children():
		child.queue_free()
	
	# Создаем заголовок
	var title = Label.new()
	title.text = "Улучшения"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(title)
	
	# Добавляем разделитель
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# Создаем секции для каждой категории улучшений
	for category in upgrade_categories.keys():
		var category_container = VBoxContainer.new()
		category_container.custom_minimum_size = Vector2(0, 80)
		
		# Заголовок категории
		var category_label = Label.new()
		category_label.text = upgrade_categories[category]
		category_label.add_theme_font_size_override("font_size", 16)
		category_container.add_child(category_label)
		
		# Информация о текущем уровне
		var current_level = UpgradeManager.current_levels.get(category, 0)
		var level_label = Label.new()
		level_label.text = "Уровень: %d" % current_level
		category_container.add_child(level_label)
		
		# Находим следующее улучшение в этой категории
		var next_upgrade = _get_next_upgrade(category)
		
		if next_upgrade:
			# Описание следующего улучшения
			var description = Label.new()
			description.text = next_upgrade.get("description", "")
			description.autowrap_mode = TextServer.AUTOWRAP_WORD
			description.custom_minimum_size = Vector2(350, 0)
			category_container.add_child(description)
			
			# Кнопка покупки
			var purchase_container = HBoxContainer.new()
			
			var cost_label = Label.new()
			cost_label.text = "Стоимость: %d₽" % next_upgrade.get("cost", 0)
			purchase_container.add_child(cost_label)
			
			var spacer = Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			purchase_container.add_child(spacer)
			
			var buy_button = Button.new()
			buy_button.text = "Купить"
			buy_button.disabled = GlobalState.money < next_upgrade.get("cost", 0)
			buy_button.pressed.connect(_on_buy_pressed.bind(category))
			purchase_container.add_child(buy_button)
			
			category_container.add_child(purchase_container)
		else:
			# Максимальный уровень
			var max_level_label = Label.new()
			max_level_label.text = "Максимальный уровень достигнут"
			max_level_label.add_theme_color_override("font_color", Color(0, 0.8, 0))
			category_container.add_child(max_level_label)
		
		vbox.add_child(category_container)
		
		# Добавляем разделитель
		vbox.add_child(HSeparator.new())

func _get_next_upgrade(category: String) -> Dictionary:
	var next_level = UpgradeManager.current_levels.get(category, 0) + 1
	var category_upgrades = DataService.upgrades.get(category, [])
	
	for upgrade in category_upgrades:
		if upgrade.get("level", 0) == next_level:
			return upgrade
	
	return {}

func _on_buy_pressed(category: String) -> void:
	# Проверяем, можно ли купить улучшение
	var next_upgrade = _get_next_upgrade(category)
	if next_upgrade.is_empty():
		return
	
	var cost = next_upgrade.get("cost", 0)
	if GlobalState.money < cost:
		return
	
	# Покупаем улучшение
	UpgradeManager.purchase_upgrade(category)
	
	upgrade_sound.play()
	# Уведомляем о покупке
	upgrade_purchased.emit(category, UpgradeManager.current_levels[category])
	
	# Обновляем интерфейс
	_initialize_ui()

func _on_close() -> void:
	visible = false

# Для открытия окна
func open() -> void:
	_initialize_ui()  # Обновляем содержимое перед показом
	visible = true
