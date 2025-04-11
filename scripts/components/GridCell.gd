class_name GridCell
extends Control

signal cell_highlighted(cell: GridCell)
signal cell_unhighlighted(cell: GridCell)
signal item_dropped(cell: GridCell, item: Node2D)

enum CellState { EMPTY, FILLED, HIGHLIGHT, LOCKED }

@export var cell_position: Vector2i  # Позиция в сетке
@export var cell_size: Vector2 = Vector2(64, 64)
@export var state: CellState = CellState.EMPTY:
	set(value):
		state = value
		update_visual_state()

# Визуальные компоненты
@onready var background: Panel = $Background
@onready var highlight: Panel = $Highlight

# Содержимое ячейки
var content: Node2D = null

func _ready() -> void:
	# Настройка размера
	custom_minimum_size = cell_size
	size = cell_size
	
	# Настройка коллизии
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Подключение к сигналам мыши
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	
	# Начальное состояние
	update_visual_state()

func update_visual_state() -> void:
	match state:
		CellState.EMPTY:
			background.modulate = Color(1, 1, 1, 0.3)
			highlight.visible = false
		CellState.FILLED:
			background.modulate = Color(1, 1, 1, 0.1)
			highlight.visible = false
		CellState.HIGHLIGHT:
			background.modulate = Color(1, 1, 1, 0.3)
			highlight.visible = true
			highlight.modulate = Color(0.2, 0.8, 0.2, 0.5)
		CellState.LOCKED:
			background.modulate = Color(0.5, 0.1, 0.1, 0.3)
			highlight.visible = false

func _on_mouse_entered() -> void:
	if state != CellState.LOCKED:
		emit_signal("cell_highlighted", self)

func _on_mouse_exited() -> void:
	if state != CellState.LOCKED:
		emit_signal("cell_unhighlighted", self)

func can_accept_item(item: Node2D) -> bool:
	# Проверяем, можно ли поместить предмет в эту ячейку
	if state == CellState.LOCKED or state == CellState.FILLED:
		return false
		
	# Дополнительные проверки на совместимость (если необходимо)
	if item is CardBase:
		# Проверка, подходит ли карта в эту ячейку
		return true
		
	return true

func set_content(new_content: Node2D) -> bool:
	if new_content == null:
		# Очищаем ячейку
		content = null
		state = CellState.EMPTY
		return true
		
	if not can_accept_item(new_content):
		return false
		
	# Устанавливаем содержимое
	content = new_content
	state = CellState.FILLED
	
	# Перемещаем содержимое в позицию ячейки
	content.global_position = global_position + cell_size/2
	
	return true

func clear_content() -> Node2D:
	var old_content = content
	content = null
	state = CellState.EMPTY
	return old_content

func highlight_as_target(is_valid: bool = true) -> void:
	if state == CellState.EMPTY:
		highlight.visible = true
		highlight.modulate = Color(0.2, 0.8, 0.2, 0.5) if is_valid else Color(0.8, 0.2, 0.2, 0.5)

func remove_highlight() -> void:
	if state != CellState.HIGHLIGHT:
		highlight.visible = false

func get_global_center() -> Vector2:
	return global_position + cell_size/2

func lock() -> void:
	state = CellState.LOCKED

func unlock() -> void:
	state = CellState.EMPTY if content == null else CellState.FILLED
