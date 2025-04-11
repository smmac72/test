class_name IngredientCard
extends Control

# Сигналы
signal card_clicked(card_data)
signal card_drag_started(card_node)
signal card_drag_ended(card_node, drop_position)

# Данные карточки
var ingredient_data: IngredientData

# Компоненты
@onready var sprite: TextureRect = $CardContainer/Sprite
@onready var name_label: Label = $CardContainer/NameLabel
@onready var count_label: Label = $CardContainer/CountLabel
@onready var quality_stars: Control = $CardContainer/QualityStars

# Состояние перетаскивания
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Настраиваем обработчики событий
	connect("gui_input", _on_gui_input)

# Настройка карточки с данными ингредиента
func setup(data: IngredientData) -> void:
	ingredient_data = data
	
	# Устанавливаем визуальные элементы
	update_visual()

# Обновление визуального представления
func update_visual() -> void:
	if not ingredient_data:
		return
	
	# Устанавливаем имя
	name_label.text = ingredient_data.name
	
	# Устанавливаем количество
	update_count(ingredient_data.count)
	
	# Устанавливаем качество
	update_quality(ingredient_data.quality)
	
	# Устанавливаем спрайт
	var sprite_path = "res://assets/images/ingredients/" + ingredient_data.sprite + ".png"
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	else:
		# Если спрайт не найден, используем заглушку
		sprite.texture = preload("res://assets/images/ingredients/default.png")

# Обновление отображения количества
func update_count(new_count: int) -> void:
	if ingredient_data:
		ingredient_data.count = new_count
	
	count_label.text = str(new_count)
	
	# Показываем или скрываем счетчик
	if new_count > 0:
		count_label.show()
	else:
		count_label.hide()

# Обновление отображения качества
func update_quality(new_quality: int) -> void:
	if ingredient_data:
		ingredient_data.quality = new_quality
	
	# Обновляем отображение звезд
	for i in range(quality_stars.get_child_count()):
		var star = quality_stars.get_child(i)
		star.visible = i < new_quality

# Получение ID ингредиента
func get_item_id() -> String:
	if ingredient_data:
		return ingredient_data.id
	return ""

# Обработчик ввода
func _on_gui_input(event: InputEvent) -> void:
	if not ingredient_data or ingredient_data.count <= 0:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Начало перетаскивания
				start_drag(event.global_position)
			else:
				# Конец перетаскивания
				end_drag(event.global_position)
				
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Клик правой кнопкой - показать информацию
			emit_signal("card_clicked", ingredient_data)

# Обработка движения мыши для перетаскивания
func _process(delta: float) -> void:
	if dragging:
		# Обновляем позицию при перетаскивании
		global_position = get_global_mouse_position() - drag_offset

# Начало перетаскивания
func start_drag(mouse_position: Vector2) -> void:
	if dragging:
		return
	
	dragging = true
	start_position = global_position
	drag_offset = mouse_position - global_position
	
	# Поднимаем z-index для отображения поверх других элементов
	z_index = 10
	
	# Отправляем сигнал о начале перетаскивания
	emit_signal("card_drag_started", self)
	
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("item_pickup", AudioManager.SoundType.GAMEPLAY)

# Окончание перетаскивания
func end_drag(mouse_position: Vector2) -> void:
	if not dragging:
		return
	
	dragging = false
	
	# Возвращаем z-index
	z_index = 0
	
	# Отправляем сигнал о завершении перетаскивания
	emit_signal("card_drag_ended", self, mouse_position)
	
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("item_drop", AudioManager.SoundType.GAMEPLAY)

# Возврат на исходную позицию
func return_to_original() -> void:
	# Анимируем возвращение карточки
	var tween = create_tween()
	tween.tween_property(self, "global_position", start_position, 0.2)
	tween.tween_property(self, "z_index", 0, 0.1)
