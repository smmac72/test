extends Panel

# Компоненты интерфейса
@onready var money_label = $HBox/LblMoney
@onready var day_label = $HBox/LblDay
@onready var time_label = $HBox/LblTime
@onready var reputation_label = $HBox/LblRep
@onready var effects_popup = $EffectsPopup
@onready var effects_list = $EffectsPopup/VBox/EffectsList
@onready var animation_player = $AnimationPlayer

# Кнопки меню
@onready var btn_menu = $HBox/Menu/BtnMenu

# Временные метки для анимации
var money_change_animation_active = false
var reputation_change_animation_active = false

# Текущие активные эффекты
var active_effects = {}

func _ready():
	# Подключаем сигналы
	GlobalState.money_changed.connect(_on_money_changed)
	GlobalState.reputation_changed.connect(_on_reputation_changed)
	GlobalState.day_passed.connect(_on_day_changed)
	
	TimeManager.minute_passed.connect(_on_time_updated)
	
	EventManager.event_triggered.connect(_on_event_triggered)
	EventManager.event_completed.connect(_on_event_completed)
	
	# Настраиваем кнопки
	btn_menu.pressed.connect(_on_menu_pressed)
	
	# Создаем анимации
	_setup_animations()
	
	# Инициализируем отображение
	_update_display()

func _update_display():
	# Обновляем отображение всех данных
	money_label.text = "₽ " + str(GlobalState.money)
	day_label.text = "ДЕНЬ " + str(GlobalState.current_day)
	reputation_label.text = "REP: " + str(GlobalState.reputation)
	
	# Обновляем время
	var hours = int(TimeManager.game_minutes / 60) % 24
	var minutes = TimeManager.game_minutes % 60
	time_label.text = "%02d:%02d" % [hours, minutes]

func _on_money_changed(new_value):
	# Определяем изменение
	var prev_value = int(money_label.text.substr(2))
	var change = new_value - prev_value
	
	# Обновляем текст
	money_label.text = "₽ " + str(new_value)
	
	# Запускаем анимацию при существенном изменении
	if abs(change) >= 10 and not money_change_animation_active:
		# Показываем всплывающую метку с изменением
		_show_value_change_label(change, true)
		
		# Запускаем анимацию пульсации
		animation_player.play("money_pulse")

func _on_reputation_changed(new_value):
	# Определяем изменение
	var prev_value = int(reputation_label.text.substr(5))
	var change = new_value - prev_value
	
	# Обновляем текст
	reputation_label.text = "REP: " + str(new_value)
	
	# Запускаем анимацию при изменении
	if abs(change) >= 1 and not reputation_change_animation_active:
		# Показываем всплывающую метку с изменением
		_show_value_change_label(change, false)
		
		# Запускаем анимацию пульсации
		animation_player.play("reputation_pulse")

func _on_day_changed(new_day):
	day_label.text = "ДЕНЬ " + str(new_day)
	
	# Анимация смены дня
	animation_player.play("day_change")

func _on_time_updated(game_minutes):
	var hours = int(game_minutes / 60) % 24
	var minutes = game_minutes % 60
	time_label.text = "%02d:%02d" % [hours, minutes]

func _show_value_change_label(change, is_money = true):
	# Создаем метку для отображения изменения
	var label = Label.new()
	var prefix = "+" if change > 0 else ""
	label.text = prefix + str(change) + ("₽" if is_money else "")
	
	# Устанавливаем цвет в зависимости от типа изменения
	if is_money:
		label.add_theme_color_override("font_color", Color(0, 1, 0) if change > 0 else Color(1, 0, 0))
	else:
		label.add_theme_color_override("font_color", Color(0, 0.8, 1) if change > 0 else Color(1, 0.5, 0))
	
	# Добавляем на сцену рядом с соответствующим значением
	add_child(label)
	
	# Позиционируем метку
	var target_label = money_label if is_money else reputation_label
	var global_rect = target_label.get_global_rect()
	label.position = Vector2(global_rect.position.x, global_rect.position.y - 20)
	
	# Анимируем исчезновение
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0, 0.8)
	tween.tween_callback(label.queue_free)

func _setup_animations():
	# Анимация пульсации денег
	var money_anim = Animation.new()
	var money_track = money_anim.add_track(Animation.TYPE_VALUE)
	money_anim.track_set_path(money_track, "HBox/LblMoney:theme_override_font_sizes/font_size")
	money_anim.track_insert_key(money_track, 0.0, 16)
	money_anim.track_insert_key(money_track, 0.1, 20)
	money_anim.track_insert_key(money_track, 0.5, 16)
	money_anim.length = 0.5
	
	# Анимация пульсации репутации
	var rep_anim = Animation.new()
	var rep_track = rep_anim.add_track(Animation.TYPE_VALUE)
	rep_anim.track_set_path(rep_track, "HBox/LblRep:theme_override_font_sizes/font_size")
	rep_anim.track_insert_key(rep_track, 0.0, 16)
	rep_anim.track_insert_key(rep_track, 0.1, 20)
	rep_anim.track_insert_key(rep_track, 0.5, 16)
	rep_anim.length = 0.5
	
	# Анимация смены дня
	var day_anim = Animation.new()
	var day_track = day_anim.add_track(Animation.TYPE_VALUE)
	day_anim.track_set_path(day_track, "HBox/LblDay:theme_override_font_sizes/font_size")
	day_anim.track_insert_key(day_track, 0.0, 16)
	day_anim.track_insert_key(day_track, 0.2, 24)
	day_anim.track_insert_key(day_track, 0.8, 16)
	day_anim.length = 0.8
	
	# Добавляем анимации в плеер
	#animation_player.add_animation("money_pulse", money_anim)
	#animation_player.add_animation("reputation_pulse", rep_anim)
	#animation_player.add_animation("day_change", day_anim)

func _on_event_triggered(event_name, payload):
	# Добавляем эффект в список активных
	active_effects[event_name] = payload
	
	# Обновляем отображение активных эффектов
	_update_effects_list()
	
	# Показываем уведомление об эффекте
	var effect_name = _get_effect_display_name(event_name)
	PopupManager.show_message("Активирован эффект: " + effect_name, 3.0, Color(1, 0.8, 0))

func _on_event_completed(event_name, _result):
	# Удаляем эффект из списка активных
	if active_effects.has(event_name):
		active_effects.erase(event_name)
		
		# Обновляем отображение активных эффектов
		_update_effects_list()
		
		# Показываем уведомление о завершении эффекта
		var effect_name = _get_effect_display_name(event_name)
		PopupManager.show_message("Эффект завершен: " + effect_name, 3.0, Color(0.5, 0.8, 1))

func _update_effects_list():
	# Очищаем список
	for child in effects_list.get_children():
		child.queue_free()
	
	# Заполняем новыми элементами
	for event_name in active_effects.keys():
		var effect_label = Label.new()
		effect_label.text = _get_effect_display_name(event_name)
		effects_list.add_child(effect_label)
	
	# Показываем или скрываем попап в зависимости от наличия эффектов
	if active_effects.size() > 0:
		effects_popup.visible = true
	else:
		effects_popup.visible = false

func _get_effect_display_name(event_name):
	match event_name:
		"police_inspection":
			return "Полицейская проверка"
		"mafia_visit":
			return "Визит крыши"
		"power_outage":
			return "Отключение электричества"
		"supplier_discount":
			return "Скидка поставщика"
		"ingredient_shortage":
			return "Дефицит ингредиентов"
		"customer_rush":
			return "Наплыв клиентов"
		"health_inspection":
			return "Санитарная проверка"
		_:
			return event_name.capitalize()

func _on_menu_pressed():
	# Переключаем состояние паузы
	GlobalState.toggle_pause()
