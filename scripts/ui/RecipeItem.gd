class_name RecipeItem
extends Control

# Сигналы
signal recipe_clicked(recipe_id)

# Компоненты
@onready var product_icon: TextureRect = $HBoxContainer/ProductIcon
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var ingredients_label: Label = $HBoxContainer/IngredientsLabel
@onready var locked_icon: TextureRect = $HBoxContainer/LockedIcon

# Данные рецепта
var recipe_data: ProductData
var is_learned: bool = false

func _ready() -> void:
	# Подключаем сигнал нажатия
	connect("gui_input", _on_gui_input)

# Настройка элемента рецепта
func setup(data: ProductData, learned: bool) -> void:
	recipe_data = data
	is_learned = learned
	
	# Заполняем данные
	name_label.text = data.name
	
	# Устанавливаем иконку продукта
	var sprite_path = "res://assets/images/products/" + data.sprite + ".png"
	if ResourceLoader.exists(sprite_path):
		product_icon.texture = load(sprite_path)
	else:
		product_icon.texture = preload("res://assets/images/products/default.png")
	
	# Отображаем ингредиенты, если рецепт изучен
	if is_learned:
		ingredients_label.text = get_ingredients_list(data)
		locked_icon.visible = false
	else:
		ingredients_label.text = "???"
		locked_icon.visible = true

# Получение списка ингредиентов
func get_ingredients_list(data: ProductData) -> String:
	var ingredients = data.ingredients
	var result = ""
	
	for i in range(ingredients.size()):
		var ingredient_id = ingredients[i]
		
		# Получаем имя ингредиента
		var production_manager = $"/root/ProductionManager"
		var ingredient = production_manager.get_ingredient(ingredient_id)
		var ingredient_name = ingredient_id
		
		if ingredient:
			ingredient_name = ingredient.name
		else:
			# Может быть, это промежуточный продукт
			var product = production_manager.get_product(ingredient_id)
			if product:
				ingredient_name = product.name
		
		result += ingredient_name
		
		# Добавляем разделитель, если не последний элемент
		if i < ingredients.size() - 1:
			result += ", "
	
	return result

# Обработчик ввода
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("recipe_clicked", recipe_data.id)
