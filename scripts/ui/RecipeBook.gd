class_name RecipeBook
extends Panel

# Сигналы
signal recipe_selected(recipe_id)
signal closed

# Компоненты
@onready var category_buttons: HBoxContainer = $VBoxContainer/CategoryButtons
@onready var recipes_container: VBoxContainer = $VBoxContainer/ScrollContainer/RecipesContainer
@onready var close_button: Button = $CloseButton

# Текущие данные
var current_production_type: String = "samogon"
var learned_recipes: Dictionary = {}

func _ready() -> void:
	# Подключаем сигналы
	close_button.connect("pressed", _on_close_button_pressed)
	
	# Подключаем кнопки категорий
	for button in category_buttons.get_children():
		if button is Button:
			button.connect("pressed", _on_category_button_pressed.bind(button.name.to_lower()))
	
	# Воспроизводим звук открытия
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("popup_open", AudioManager.SoundType.UI)

# Обновление книги рецептов
func update_recipes(production_type: String, learned: Dictionary) -> void:
	current_production_type = production_type
	learned_recipes = learned
	
	# Обновляем выбранную категорию
	for button in category_buttons.get_children():
		if button is Button:
			var category = button.name.to_lower()
			button.button_pressed = (category == production_type)
	
	# Загружаем рецепты для выбранной категории
	load_recipes_for_category(production_type)

# Загрузка рецептов для категории
func load_recipes_for_category(category: String) -> void:
	# Очищаем контейнер
	for child in recipes_container.get_children():
		child.queue_free()
	
	# Получаем рецепты от производственного менеджера
	var production_manager = $"/root/ProductionManager"
	var recipes = []
	
	# Получаем промежуточные и конечные продукты
	var intermediate_products = production_manager.get_products_by_type(category, false)
	var final_products = production_manager.get_products_by_type(category, true)
	
	# Объединяем все продукты
	recipes.append_array(intermediate_products)
	recipes.append_array(final_products)
	
	# Сортируем по типу (сначала промежуточные, потом конечные)
	recipes.sort_custom(func(a, b): return a.is_final < b.is_final)
	
	# Добавляем рецепты в контейнер
	for recipe in recipes:
		var recipe_item = preload("res://scenes/ui/RecipeItem.tscn").instantiate()
		recipe_item.setup(recipe, learned_recipes.get(recipe.id, false))
		recipe_item.connect("recipe_clicked", _on_recipe_clicked)
		recipes_container.add_child(recipe_item)

# Обработчик нажатия на кнопку категории
func _on_category_button_pressed(category: String) -> void:
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	current_production_type = category
	load_recipes_for_category(category)

# Обработчик нажатия на рецепт
func _on_recipe_clicked(recipe_id: String) -> void:
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	emit_signal("recipe_selected", recipe_id)

# Обработчик нажатия на кнопку закрытия
func _on_close_button_pressed() -> void:
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("popup_close", AudioManager.SoundType.UI)
	
	hide()
	emit_signal("closed")
