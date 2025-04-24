extends CanvasLayer

# Текущие активные попапы
var active_popups = []

# Очередь для диалогов (чтобы они не перекрывали друг друга)
var dialog_queue = []
var is_dialog_active = false

# Сигналы
signal dialog_closed(result)

func _ready():
	# Создаем слой поверх всего интерфейса
	layer = 10

# Показать простое сообщение, которое исчезнет через указанное время
func show_message(text: String, duration: float = 3.0, color: Color = Color(1, 1, 0)):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 20)
	
	# Добавляем фон для лучшей читаемости
	var panel = PanelContainer.new()
	panel.add_child(label)
	
	add_child(panel)
	active_popups.append(panel)
	
	# Позиционируем по центру верхней части экрана
	panel.position = Vector2(
		get_viewport().size.x / 2 - panel.size.x / 2,
		100
	)
	
	# Анимация появления и исчезновения
	panel.modulate = Color(1, 1, 1, 0)
	
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.tween_interval(duration)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		active_popups.erase(panel)
		panel.queue_free()
	)

# Показать полноценный диалог с кнопками
func show_dialog(title: String, message: String, buttons: Array):
	# Добавляем в очередь
	dialog_queue.append({
		"title": title,
		"message": message,
		"buttons": buttons
	})
	
	# Если нет активного диалога, показываем следующий
	if not is_dialog_active:
		_show_next_dialog()

# Показать диалог с подтверждением (ОК/Отмена)
func show_confirm_dialog(title: String, message: String, on_confirm = null, on_cancel = null):
	var buttons = []
	
	if on_confirm:
		buttons.append({
			"text": "OK",
			"callback": "_handle_dialog_result",
			"args": [on_confirm, true]
		})
	else:
		buttons.append({"text": "OK", "callback": "_close_dialog"})
	
	if on_cancel:
		buttons.append({
			"text": "Отмена",
			"callback": "_handle_dialog_result",
			"args": [on_cancel, false]
		})
	else:
		buttons.append({"text": "Отмена", "callback": "_close_dialog"})
	
	show_dialog(title, message, buttons)

# Внутренний метод для показа следующего диалога из очереди
func _show_next_dialog():
	if dialog_queue.size() == 0:
		is_dialog_active = false
		return
	
	is_dialog_active = true
	var dialog_data = dialog_queue.pop_front()
	
	# Создаем диалог
	var dialog = _create_dialog(
		dialog_data["title"],
		dialog_data["message"],
		dialog_data["buttons"]
	)
	
	# Показываем диалог
	add_child(dialog)
	active_popups.append(dialog)
	
	# Центрируем диалог
	call_deferred("_center_dialog", dialog)

# Создает диалоговое окно
func _create_dialog(title: String, message: String, buttons: Array) -> Control:
	# Создаем контейнер для диалога
	var dialog = PanelContainer.new()
	dialog.name = "Dialog"
	
	# Добавляем тени и стили
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_size = 5
	style_box.shadow_offset = Vector2(2, 2)
	dialog.add_theme_stylebox_override("panel", style_box)
	
	# Основной контейнер
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 200)
	dialog.add_child(vbox)
	
	# Заголовок
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(title_label)
	
	# Разделитель
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# Сообщение
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var message_label = Label.new()
	message_label.text = message
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	message_label.custom_minimum_size = Vector2(380, 0)
	scroll.add_child(message_label)
	
	# Кнопки
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(button_container)
	
	for button_data in buttons:
		var button = Button.new()
		button.text = button_data["text"]
		button.custom_minimum_size = Vector2(80, 30)
		
		var callback = button_data.get("callback", "_close_dialog")
		var args = button_data.get("args", [])
		
		if callback in self:
			button.pressed.connect(Callable(self, callback).bind(args))
		
		button_container.add_child(button)
	
	return dialog

# Центрирует диалог на экране
func _center_dialog(dialog: Control):
	dialog.position = get_viewport().size / 2 - dialog.size / 2

# Закрывает текущий диалог
func _close_dialog(args = []):
	if active_popups.size() == 0:
		return
	
	var dialog = active_popups.pop_back()
	if dialog:
		dialog.queue_free()
	
	# Показываем следующий диалог в очереди
	call_deferred("_show_next_dialog")

# Обработчик результата диалога
func _handle_dialog_result(args):
	if args.size() >= 2:
		var callback = args[0]
		var result = args[1]
		
		# Если задан колбэк, вызываем его
		if callback is Callable:
			callback.call(result)
	
	# Закрываем диалог
	_close_dialog()

# Очистить все попапы (например, при смене сцены)
func clear_all():
	for popup in active_popups:
		popup.queue_free()
	
	active_popups.clear()
	dialog_queue.clear()
	is_dialog_active = false
