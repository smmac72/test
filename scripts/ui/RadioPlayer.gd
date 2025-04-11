class_name RadioPlayer
extends Control

# Сигналы
signal station_changed(station_id)
signal volume_changed(volume)

# Компоненты
@onready var play_button: Button = $PlayButton
@onready var next_button: Button = $NextButton
@onready var volume_slider: HSlider = $VolumeSlider

# Данные радио
var stations: Array = [
	{
		"id": "station_1",
		"name": "Шансон",
		"playlist": ["shanson_1", "shanson_2", "shanson_3"]
	},
	{
		"id": "station_2",
		"name": "Поп",
		"playlist": ["pop_1", "pop_2", "pop_3"]
	},
	{
		"id": "station_3",
		"name": "Рок",
		"playlist": ["rock_1", "rock_2", "rock_3"]
	}
]

var current_station_index: int = 0
var is_playing: bool = false
var volume: float = 0.5

func _ready() -> void:
	# Подключаем сигналы
	play_button.connect("pressed", _on_play_button_pressed)
	next_button.connect("pressed", _on_next_button_pressed)
	volume_slider.connect("value_changed", _on_volume_slider_changed)
	
	# Настраиваем слайдер громкости
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = volume

# Обработчики кнопок
func _on_play_button_pressed() -> void:
	is_playing = !is_playing
	
	if is_playing:
		play_button.text = "⏹"
		start_playback()
	else:
		play_button.text = "▶"
		stop_playback()

func _on_next_button_pressed() -> void:
	current_station_index = (current_station_index + 1) % stations.size()
	
	if is_playing:
		stop_playback()
		start_playback()
	
	emit_signal("station_changed", stations[current_station_index]["id"])

func _on_volume_slider_changed(value: float) -> void:
	volume = value
	emit_signal("volume_changed", volume)

# Управление воспроизведением
func start_playback() -> void:
	# Получаем текущую станцию
	var station = stations[current_station_index]
	
	# Выбираем случайную песню из плейлиста
	var playlist = station["playlist"]
	var track = playlist[randi() % playlist.size()]
	
	# Запускаем воспроизведение
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_music(track, volume)

func stop_playback() -> void:
	# Останавливаем воспроизведение
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.stop_music()
