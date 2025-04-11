extends Panel

# Компоненты UI
@onready var master_volume_slider: HSlider = $VBoxContainer/MasterVolumeContainer/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $VBoxContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $VBoxContainer/SFXVolumeContainer/SFXVolumeSlider
@onready var ui_volume_slider: HSlider = $VBoxContainer/UIVolumeContainer/UIVolumeSlider
@onready var close_button: Button = $CloseButton

# Ссылки на менеджеры
@onready var game_manager: GameManager = $"/root/GameManager"
@onready var audio_manager: AudioManager = $"/root/AudioManager"

func _ready() -> void:
	# Подключение сигналов слайдеров
	master_volume_slider.connect("value_changed", _on_master_volume_changed)
	music_volume_slider.connect("value_changed", _on_music_volume_changed)
	sfx_volume_slider.connect("value_changed", _on_sfx_volume_changed)
	ui_volume_slider.connect("value_changed", _on_ui_volume_changed)
	
	# Подключение сигнала кнопки закрытия
	close_button.connect("pressed", _on_close_button_pressed)
	
	# Загрузка текущих настроек
	load_current_settings()

# Загрузка текущих настроек
func load_current_settings() -> void:
	# Получаем текущие настройки
	var settings = game_manager.settings
	
	# Устанавливаем значения слайдеров
	master_volume_slider.value = settings.get("master_volume", 1.0)
	music_volume_slider.value = settings.get("music_volume", 0.7)
	sfx_volume_slider.value = settings.get("sfx_volume", 0.8)
	ui_volume_slider.value = settings.get("ui_volume", 0.5)

# Обработчики изменения громкости
func _on_master_volume_changed(value: float) -> void:
	# Воспроизводим тестовый звук
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	# Сохраняем настройку
	game_manager.change_setting("master_volume", value)

func _on_music_volume_changed(value: float) -> void:
	# Сохраняем настройку
	game_manager.change_setting("music_volume", value)

func _on_sfx_volume_changed(value: float) -> void:
	# Воспроизводим тестовый звук
	if audio_manager:
		audio_manager.play_sound("item_place", AudioManager.SoundType.GAMEPLAY)
	
	# Сохраняем настройку
	game_manager.change_setting("sfx_volume", value)

func _on_ui_volume_changed(value: float) -> void:
	# Воспроизводим тестовый звук
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	# Сохраняем настройку
	game_manager.change_setting("ui_volume", value)

# Обработчик кнопки закрытия
func _on_close_button_pressed() -> void:
	# Воспроизводим звук нажатия
	if audio_manager:
		audio_manager.play_sound("button_click", AudioManager.SoundType.UI)
	
	# Скрываем панель настроек
	visible = false
