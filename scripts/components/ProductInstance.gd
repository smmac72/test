class_name ProductInstance
extends Node2D

# Сигналы
signal product_clicked(product_data)
signal product_drag_started(product_node)
signal product_drag_ended(product_node, drop_position)

# Данные продукта
var product_data: ProductData

# Компоненты
@onready var sprite: Sprite2D = $Sprite2D
@onready var quality_stars: Node2D = $QualityStars
@onready var count_label: Label = $CountLabel

# Состояние перетаскивания
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Настраиваем обработчики событий
	input_pickable = true
	connect("input_event", _on_input_event)

# Настройка продукта
func setup(data: ProductData) -> void:
	product_data = data
	
	# Устанавливаем визуальные элементы
	update_visual()

# Обновление визуального представления
func update_visual() -> void:
	if not product_data:
		return
	
	# Устанавливаем спрайт
	var sprite_path = "res://assets/images/products/" + product_data.sprite + ".png"
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	else:
		# Если спрайт не найден, используем заглушку
		sprite.texture = preload("res://assets/images/products/default.png")
	
	# Устанавливаем количество
	update_count(product_data.count)
	
	# Устанавливаем качество
	update_quality(product_data.quality)

# Обновление отображения количества
func update_count(new_count: int) -> void:
	if product_data:
		product_data.count = new_count
	
	count_label.text = str(new_count)
	
	# Показываем или скрываем счетчик
	if new_count > 0:
		count_label.show()
	else:
		count_label.hide()

# Обновление отображения качества
func update_quality(new_quality: int) -> void:
	if product_data:
		product_data.quality = new_quality
	
	# Обновляем отображение звезд
	for i in range(quality_stars.get_child_count()):
		var star = quality_stars.get_child(i)
		star.visible = i < new_quality

# Обработчик события ввода
func _on_input_event(viewport, event, shape_idx) -> void:
	if not product_data or product_data.count <= 0:
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
			emit_signal("product_clicked", product_data)

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
	
	# Поднимаем слой отображения
	z_index = 10
	
	# Отправляем сигнал о начале перетаскивания
	emit_signal("product_drag_started", self)
	
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("item_pickup", AudioManager.SoundType.GAMEPLAY)

# Окончание перетаскивания
func end_drag(mouse_position: Vector2) -> void:
	if not dragging:
		return
	
	dragging = false
	
	# Возвращаем слой отображения
	z_index = 0
	
	# Отправляем сигнал о завершении перетаскивания
	emit_signal("product_drag_ended", self, mouse_position)
	
	# Воспроизводим звук
	var audio_manager = $"/root/AudioManager"
	if audio_manager:
		audio_manager.play_sound("item_drop", AudioManager.SoundType.GAMEPLAY)

# Возврат на исходную позицию
func return_to_original() -> void:
	# Анимируем возвращение
	var tween = create_tween()
	tween.tween_property(self, "global_position", start_position, 0.2)
	tween.tween_property(self, "z_index", 0, 0.1)
