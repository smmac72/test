extends Control

# Компоненты UI
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var new_game_button: Button = $VBoxContainer/ButtonsContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ButtonsContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/ButtonsContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ButtonsContainer/ExitButton
@onready var version_label: Label = $VersionLabel
@onready var settings_panel: Panel = $SettingsPanel

# Ссылки на менеджеры
@onready var game_manager: GameManager = $"/root/GameManager"
@onready var audio_manager: AudioManager = $"/root/AudioManager"

# Версия игры
const VERSION: String = "0.1.0"

func _ready() -> void:
	# Настройка элементов UI
	title_label.text = "samogon.exe"
	version_label.text = "v" + VERSION
	
	# Проверка наличия сохранения для кнопки продолжения
	check_save_exists()
	
	# Подключение сигналов кнопок
	new_game_button.connect("pressed", _on_new_game_button_pressed)
	continue_button.connect("pressed", _on_continue_button_pressed)
	settings_button.connect("pressed", _on_settings_button_pressed)
	exit_button.connect("pressed", _on_exit_button_pressed)
	
	# Скрываем настройки при старте
	settings_panel.visible = false
	
	# Воспроизводим фоновую музыку
	if audio_manager:
		audio_manager.play_music("menu_theme")

# Проверка наличия сохранения
func check_save_exists() -> void:
	var save_exists = false
	
	# Проверяем локальное сохранение
	if FileAccess.file_exists("user://samogon_save.json"):
		save_exists = true
	
	# Проверяем веб-сохранение
	if OS.has_feature("web"):
		var has_save = JavaScript.eval("""
		try {
			return localStorage.getItem('samogon_save') ? true : false;
		} catch (e) {
			return false;
		}
		""")
		
		if has_save:
			save_exists = true
	
	# Включаем/выключаем кнопку продолжения
	continue_button.disabled = !save_exists

# Обработчики кнопок
func _on_new_game_button_pressed() -> void:
	# Воспроизводим звук нажатия
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	# Проверяем, есть ли сохранение, и если есть, спрашиваем подтверждение
	if continue_button.disabled == false:
		show_new_game_confirmation()
	else:
		# Сразу начинаем новую игру
		start_new_game()

func _on_continue_button_pressed() -> void:
	# Воспроизводим звук нажатия
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	# Загружаем сохраненную игру
	game_manager.is_new_game = false
	get_tree().change_scene_to_file("res://scenes/global/MainScene.tscn")

func _on_settings_button_pressed() -> void:
	# Воспроизводим звук нажатия
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	# Показываем настройки
	settings_panel.visible = true

func _on_exit_button_pressed() -> void:
	# Воспроизводим звук нажатия
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	# Выходим из игры
	get_tree().quit()

# Начало новой игры
func start_new_game() -> void:
	# Сбрасываем состояние игры
	game_manager.is_new_game = true
	
	# Переходим на основную сцену
	get_tree().change_scene_to_file("res://scenes/global/MainScene.tscn")

# Показ диалога подтверждения начала новой игры
func show_new_game_confirmation() -> void:
	# Создаем диалог подтверждения
	var dialog = ConfirmationDialog.new()
	dialog.title = "Начать новую игру?"
	dialog.dialog_text = "Существующее сохранение будет перезаписано. Вы уверены?"
	dialog.get_ok_button().text = "Да"
	dialog.get_cancel_button().text = "Нет"
	
	# Подключаем сигналы
	dialog.confirmed.connect(_on_new_game_confirmed)
	
	# Показываем диалог
	add_child(dialog)
	dialog.popup_centered()

# Обработчик подтверждения новой игры
func _on_new_game_confirmed() -> void:
	start_new_game()
