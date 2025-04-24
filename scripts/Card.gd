extends TextureRect
class_name Card

signal card_dropped(target)

var item_data: Dictionary = {}
var original_parent = null
var original_position = Vector2.ZERO
var dragging = false
var quality: int = 0  # Качество от 0 до 3 (0-3 звезды)
var is_template_card := false 
@onready var take_sound = $TakeCard
@onready var drop_sound = $PlaceCard
@onready var entered_sound = $NavelCard
@onready var drop_bottle = $PlaceBottle
@onready var give_money_sound = $GiveMoney
var item_type 
var is_final: bool = false
# Цвета для разных типов продуктов
var type_colors = {
	"base": Color(0.4, 0.7, 1.0, 0.7),            # Основа (вода) - голубой
	"mash_ingredient": Color(0.7, 0.5, 0.3, 0.7), # Ингредиенты для браги - коричневый
	"fermentation": Color(0.8, 0.8, 0.2, 0.7),    # Ферментация - желтый
	"flavor": Color(0.8, 0.4, 0.8, 0.7),          # Вкусовые добавки - пурпурный
	"mash": Color(0.5, 0.75, 0.4, 0.7),           # Брага - зеленый
	"base_alcohol": Color(0.9, 0.9, 0.9, 0.7),    # Основа для настоек - белый
	"final_product": Color(0.9, 0.4, 0.4, 0.7),   # Готовые продукты - красный
	"tool": Color(0.5, 0.5, 0.5, 0.7)             # Инструменты - серый
}

# Производственные типы
var production_colors = {
	"samogon": Color(0.95, 0.6, 0.2, 0.3),        # Самогон - оранжевый оттенок
	"beer": Color(0.7, 0.5, 0.2, 0.3),            # Пиво - коричневый оттенок
	"wine": Color(0.7, 0.2, 0.4, 0.3)             # Вино - бордовый оттенок
}

func _ready():
	give_money_sound.bus="&Sfx"
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	take_sound.bus="&Sfx"
	drop_sound.bus="&Sfx" 
	entered_sound.bus="&Sfx"
	drop_bottle.bus="&Sfx"
	# Добавляем фон для карточки, чтобы лучше различать
	if not has_node("Background"):
		var bg = ColorRect.new()
		bg.name = "Background"
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.show_behind_parent = true
		bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(bg)
		bg.position = Vector2(0, 0)
		bg.size = size
	
	# Настраиваем внешний вид карточки на основе типа
	_update_card_appearance()

func set_item(data: Dictionary) -> void:
	item_data = data
	update_view()
	_update_card_appearance()

func update_view() -> void:
	if has_node("Label"):
		$Label.text = item_data.get("name", "")
		
		var type = item_data.get("type", "")
		# костыль ебани
		if type == "tool":
			$Label.position += Vector2(0, 30)
			$Label.add_theme_color_override("font_color", Color(0, 0, 0))
	
	if item_data.has("sprite"):
		var path = "res://art/%s.png" % item_data.get("sprite", "placeholder")
		if ResourceLoader.exists(path):
			texture = load(path)
		else:
			texture = null
	
	# Отображаем качество (звезды)
	if has_node("Quality"):
		$Quality.text = "⭐".repeat(quality) if quality > 0 else ""
	
	# Обновляем размер фона, если он есть
	if has_node("Background"):
		$Background.size = size

func set_quality(q: int) -> void:
	quality = clampi(q, 0, 3)
	update_view()

func get_quality() -> int:
	return quality

func _get_drag_data(_pos):
	var type=item_data.get("type", "")
	if (type != "tool"):
		original_parent = get_parent()
		original_position = position
		dragging = true
		take_sound.play()
		if self.get_parent() is Slot:
			self.get_parent().remove_card()
	
		var preview := duplicate() as TextureRect
		preview.self_modulate.a = 0.7
		set_drag_preview(preview)
	
		if is_template_card:
			var copy = duplicate()
			copy.set_item(item_data)
			copy.set_quality(get_quality())
			copy.custom_minimum_size = custom_minimum_size
			copy.is_template_card = false
			copy.global_position = get_global_position()
		
			preview.texture = texture
			preview.expand = true
			preview.stretch_mode = STRETCH_KEEP_ASPECT_CENTERED
			give_money_sound.play()
			set_drag_preview(preview)
			return copy
		else:
			original_parent = get_parent()
			original_position = position
			
			preview.texture = texture
			preview.expand = true
			preview.stretch_mode = STRETCH_KEEP_ASPECT_CENTERED

			set_drag_preview(preview)
			return self
		
func get_type () -> String:
	return item_type
func _input(event):
	
	# Обработка отмены перетаскивания при отпускании кнопки мыши
	if dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# Если после перетаскивания карточка не имеет родителя,
		# значит она не была размещена в допустимом месте, и нужно вернуть её обратно
		if not is_inside_tree() or get_parent() != original_parent:
			cancel_drag()

func _on_mouse_entered():
	entered_sound.play()
	if has_node("DescPopup") and !dragging:
		$DescPopup.visible = true
		
	
	# Подсветка при наведении
	if has_node("Background"):
		$Background.self_modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_mouse_exited():
	if has_node("DescPopup"):
		$DescPopup.visible = false
	
	# Возвращаем нормальный цвет
	if has_node("Background"):
		$Background.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func cancel_drag():
	dragging = false
	#drop_sound.play()
	
	# Проверяем, существует ли оригинальный родитель
	if not is_instance_valid(original_parent):
		queue_free()  # Если родитель больше не существует, удаляем карточку
		return
	
	# Возвращаем на исходное место
	if get_parent() != original_parent:
		if is_inside_tree():
			get_parent().remove_child(self)
		
		original_parent.add_child(self)
	
	# Восстанавливаем позицию
	position = original_position
	
	# Обновляем отображение
	update_view()
	_update_card_appearance()

func _update_card_appearance():
	if not has_node("Background"):
		return
	
	var bg = $Background
	
	# Базовый цвет по типу
	item_type = item_data.get("type", "")
	if type_colors.has(item_type):
		bg.color = type_colors[item_type]
		
	else:
		bg.color = Color(0.7, 0.7, 0.7, 0.7)  # Стандартный серый
	
	# Добавляем оттенок производственного типа
	var prod_type = item_data.get("production_type", "")
	if production_colors.has(prod_type):
		# Смешиваем цвета
		bg.color = bg.color.lerp(production_colors[prod_type], 0.3)
	
	# Обновляем размер фона
	bg.size = size
