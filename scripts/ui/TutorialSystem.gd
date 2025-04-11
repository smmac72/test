class_name TutorialSystem
extends CanvasLayer

# Сигналы
signal tutorial_completed
signal tutorial_step_changed(step)

# Компоненты UI
@onready var highlight_rect: ColorRect = $HighlightRect
@onready var tutorial_panel: Panel = $TutorialPanel
@onready var title_label: Label = $TutorialPanel/TitleLabel
@onready var description_label: Label = $TutorialPanel/DescriptionLabel
@onready var next_button: Button = $TutorialPanel/NextButton
@onready var skip_button: Button = $TutorialPanel/SkipButton

# Шаги туториала
var tutorial_steps: Array = [
	{
		"title": "Добро пожаловать!",
		"description": "Добро пожаловать в игру samogon.exe! Здесь вы будете управлять подпольным производством алкоголя. Давайте познакомимся с основными механиками.",
		"highlight_node_path": "",
		"highlight_expand": Vector2(0, 0)
	},
	{
		"title": "Интерфейс",
		"description": "Сверху вы видите панель с вашими деньгами, репутацией и текущим днем. Левая часть экрана - это магазин, правая - производство.",
		"highlight_node_path": "MainUI/VSplitContainer/TopBar",
		"highlight_expand": Vector2(20, 10)
	},
	{
		"title": "Производство",
		"description": "В правой части экрана находится производство. Здесь вы будете создавать различные алкогольные напитки. Сначала вам доступно только самогоноварение.",
		"highlight_node_path": "MainUI/VSplitContainer/ContentContainer/ProductionUI",
		"highlight_expand": Vector2(20, 20)
	},
	{
		"title": "Ингредиенты",
		"description": "Внизу экрана производства находятся ваши ингредиенты. Вы можете перетаскивать их на рабочую область или в инструменты для создания продуктов.",
		"highlight_node_path": "MainUI/VSplitContainer/ContentContainer/ProductionUI/VBoxContainer/IngredientsPanel",
		"highlight_expand": Vector2(20, 10)
	},
	{
		"title": "Инструменты",
		"description": "Здесь находятся ваши инструменты для производства. Перетащите инструмент на рабочую область, а затем добавьте в него необходимые ингредиенты.",
		"highlight_node_path": "MainUI/VSplitContainer/ContentContainer/ProductionUI/VBoxContainer/ToolsPanel",
		"highlight_expand": Vector2(20, 10)
	},
	{
		"title": "Книга рецептов",
		"description": "Нажмите на кнопку 'Книга рецептов', чтобы увидеть доступные вам рецепты. Новые рецепты открываются по мере улучшения производства.",
		"highlight_node_path": "MainUI/VSplitContainer/ContentContainer/ProductionUI/VBoxContainer/ButtonPanel",
		"highlight_expand": Vector2(20, 10)
	},
	{
		"title": "Магазин",
		"description": "Левая часть экрана - это магазин, где к вам будут приходить клиенты. Здесь вы будете продавать созданные напитки.",
		"highlight_node_path": "MainUI/VSplitContainer/ContentContainer/ShopUI",
		"highlight_expand": Vector2(20, 20)
	},
	{
		"title": "Клиенты",
		"description": "В этой области появляются клиенты. Каждый клиент имеет свои предпочтения и платежеспособность. Вам нужно удовлетворять их запросы.",
		"highlight_node_path": "MainUI/VSplitContainer/ContentContainer/ShopUI/VBoxContainer/ShopArea/VBoxContainer/CustomerArea",
		"highlight_expand": Vector2(20, 20)
	},
	{
		"title": "Склад",
		"description": "Здесь хранятся ваши готовые напитки. Вы можете перетаскивать их отсюда клиентам для продажи. Также вы можете изменять цены на продукцию.",
		"highlight_node_path": "MainUI/VSplitContainer/ContentContainer/ShopUI/VBoxContainer/ShopArea/VBoxContainer/StoragePanel",
		"highlight_expand": Vector2(20, 10)
	},
	{
		"title": "Начало игры",
		"description": "Теперь вы знаете основы! Начните с создания простого самогона: перетащите бродильный чан на рабочую область, добавьте воду, сахар и кодзи, затем запустите процесс.",
		"highlight_node_path": "",
		"highlight_expand": Vector2(0, 0)
	}
]

# Текущий шаг
var current_step: int = 0
var total_steps: int = 0

func _ready() -> void:
	# Подключение сигналов кнопок
	next_button.connect("pressed", _on_next_button_pressed)
	skip_button.connect("pressed", _on_skip_button_pressed)
	
	# Инициализация
	total_steps = tutorial_steps.size()
	update_tutorial_step()
	
	# Устанавливаем слой выше основного UI
	layer = 10

# Запуск туториала
func start_tutorial() -> void:
	current_step = 0
	update_tutorial_step()
	show()

# Обновление шага туториала
func update_tutorial_step() -> void:
	if current_step >= total_steps:
		# Туториал завершен
		complete_tutorial()
		return
	
	# Получаем данные текущего шага
	var step = tutorial_steps[current_step]
	
	# Обновляем текст
	title_label.text = step["title"]
	description_label.text = step["description"]
	
	# Обновляем подсветку
	update_highlight(step["highlight_node_path"], step["highlight_expand"])
	
	# Обновляем текст кнопки
	if current_step == total_steps - 1:
		next_button.text = "Завершить"
	else:
		next_button.text = "Далее"
	
	# Отправляем сигнал об изменении шага
	emit_signal("tutorial_step_changed", current_step)

# Обновление подсветки
func update_highlight(node_path: String, expand: Vector2) -> void:
	if node_path.is_empty():
		# Если путь пустой, скрываем подсветку
		highlight_rect.visible = false
		return
	
	# Получаем узел для подсветки
	var node = get_node_or_null("/root/MainScene/" + node_path)
	if not node:
		highlight_rect.visible = false
		return
	
	# Получаем глобальные координаты и размеры узла
	var rect = Rect2(node.global_position, node.size)
	
	# Расширяем прямоугольник
	rect = rect.grow_individual(expand.x, expand.y, expand.x, expand.y)
	
	# Устанавливаем подсветку
	highlight_rect.visible = true
	highlight_rect.global_position = rect.position
	highlight_rect.size = rect.size

# Обработчики кнопок
func _on_next_button_pressed() -> void:
	# Воспроизводим звук нажатия
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	# Переходим к следующему шагу
	current_step += 1
	update_tutorial_step()

func _on_skip_button_pressed() -> void:
	# Воспроизводим звук нажатия
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	# Пропускаем туториал
	complete_tutorial()

# Завершение туториала
func complete_tutorial() -> void:
	# Отправляем сигнал о завершении
	emit_signal("tutorial_completed")
	
	# Сохраняем, что туториал пройден
	var game_manager = $"/root/GameManager"
	game_manager.change_setting("tutorial_completed", true)
	
	# Скрываем туториал
	hide()
