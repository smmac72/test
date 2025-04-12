class_name AudioManager
extends Node

# Группы звуков
enum SoundType { UI, GAMEPLAY, AMBIENT, MUSIC }

# Аудио плееры
var music_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var gameplay_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

# Пулы плееров для одновременного воспроизведения
var ui_players_pool: Array = []
var gameplay_players_pool: Array = []

# Настройки громкости
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var ui_volume: float = 0.5
var ambient_volume: float = 0.6

# Пути к звукам
var sound_paths: Dictionary = {
	# UI звуки
	"button_click": "res://assets/audio/ui/button_click.ogg",
	"popup_open": "res://assets/audio/ui/popup_open.ogg",
	"popup_close": "res://assets/audio/ui/popup_close.ogg",
	"money_gain": "res://assets/audio/ui/money_gain.ogg",
	"money_loss": "res://assets/audio/ui/money_loss.ogg",
	
	# Игровые звуки
	"item_pickup": "res://assets/audio/gameplay/item_pickup.ogg",
	"item_place": "res://assets/audio/gameplay/item_place.ogg",
	"item_drop": "res://assets/audio/gameplay/item_drop.ogg",
	"production_start": "res://assets/audio/gameplay/production_start.ogg",
	"production_complete": "res://assets/audio/gameplay/production_complete.ogg",
	"customer_enter": "res://assets/audio/gameplay/customer_enter.ogg",
	"customer_exit": "res://assets/audio/gameplay/customer_exit.ogg",
	"sale_success": "res://assets/audio/gameplay/sale_success.ogg",
	"sale_fail": "res://assets/audio/gameplay/sale_fail.ogg",
	
	# Фоновые звуки
	"ambient_day": "res://assets/audio/ambient/ambient_day.ogg",
	"ambient_night": "res://assets/audio/ambient/ambient_night.ogg",
	
	# Музыка
	"shanson_1": "res://assets/audio/music/shanson_1.ogg",
	"shanson_2": "res://assets/audio/music/shanson_2.ogg",
	"shanson_3": "res://assets/audio/music/shanson_3.ogg",
	"pop_1": "res://assets/audio/music/pop_1.ogg",
	"pop_2": "res://assets/audio/music/pop_2.ogg",
	"pop_3": "res://assets/audio/music/pop_3.ogg",
	"rock_1": "res://assets/audio/music/rock_1.ogg",
	"rock_2": "res://assets/audio/music/rock_2.ogg",
	"rock_3": "res://assets/audio/music/rock_3.ogg"
}

# Инициализация
func _ready() -> void:
	# Создаем основные плееры
	music_player = create_audio_player()
	if music_player == null:
		push_error("AudioManager: не удалось создать музыкальный плеер")
	ui_player = create_audio_player()
	gameplay_player = create_audio_player()
	ambient_player = create_audio_player()
	
	# Настраиваем свойства плееров
	music_player.bus = "Music"
	ui_player.bus = "UI"
	gameplay_player.bus = "SFX"
	ambient_player.bus = "Ambient"
	
	# Создаем пулы плееров
	for i in range(5):
		var player = create_audio_player()
		player.bus = "UI"
		ui_players_pool.append(player)
	
	for i in range(10):
		var player = create_audio_player()
		player.bus = "SFX"
		gameplay_players_pool.append(player)
	
	# Подключаем обработчик окончания музыки
	music_player.connect("finished", _on_music_finished)

# Создание аудио плеера
func create_audio_player() -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	add_child(player)
	return player

# Воспроизведение звука
func play_sound(sound_name: String, type: int = SoundType.GAMEPLAY, volume_override: float = -1.0) -> void:
	# Проверяем наличие звука
	if not sound_name in sound_paths:
		push_warning("Звук не найден: " + sound_name)
		return
	
	# Загружаем звук
	var sound_path = sound_paths[sound_name]
	var stream = load_audio_stream(sound_path)
	
	if stream == null:
		push_error("Не удалось загрузить звук: " + sound_path)
		return
	
	# Выбираем плеер в зависимости от типа звука
	var player = null
	
	match type:
		SoundType.UI:
			# Используем плеер из пула UI
			player = get_free_player_from_pool(ui_players_pool)
		SoundType.GAMEPLAY:
			# Используем плеер из пула геймплея
			player = get_free_player_from_pool(gameplay_players_pool)
		SoundType.AMBIENT:
			# Используем основной ambient плеер
			player = ambient_player
		SoundType.MUSIC:
			# Музыка имеет отдельный метод
			play_music(sound_name, volume_override)
			return
	
	if player == null:
		push_warning("Не удалось найти свободный плеер для звука: " + sound_name)
		return
	
	# Настраиваем плеер
	player.stream = stream
	
	# Устанавливаем громкость
	var volume = volume_override if volume_override >= 0 else get_volume_for_type(type)
	player.volume_db = linear_to_db(volume * master_volume)
	
	# Воспроизводим звук
	player.play()

# Воспроизведение музыки
func play_music(track_name: String, volume_override: float = -1.0) -> void:
	# Проверяем наличие трека
	if not track_name in sound_paths:
		push_warning("Трек не найден: " + track_name)
		return
	
	# Загружаем трек
	var track_path = sound_paths[track_name]
	var stream = load_audio_stream(track_path)
	
	if stream == null:
		push_error("Не удалось загрузить трек: " + track_path)
		return
	
	# Останавливаем текущую музыку
	if music_player.playing:
		music_player.stop()
	
	# Настраиваем плеер
	music_player.stream = stream
	
	# Устанавливаем громкость
	var volume = volume_override if volume_override >= 0 else music_volume
	music_player.volume_db = linear_to_db(volume * master_volume)
	
	# Воспроизводим музыку
	music_player.play()

# Остановка музыки
func stop_music() -> void:
	if music_player.playing:
		music_player.stop()

# Загрузка аудио потока
func load_audio_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		# Проверяем, существует ли файл в проекте
		push_error("Аудио файл не найден: " + path)
		return null
	
	# Загружаем звук
	return ResourceLoader.load(path)

# Получение свободного плеера из пула
func get_free_player_from_pool(pool: Array) -> AudioStreamPlayer:
	for player in pool:
		if not player.playing:
			return player
	
	# Если все плееры заняты, возвращаем первый (перезаписываем)
	if pool.size() > 0:
		return pool[0]
	
	return null

# Получение громкости для типа звука
func get_volume_for_type(type: int) -> float:
	match type:
		SoundType.UI:
			return ui_volume
		SoundType.GAMEPLAY:
			return sfx_volume
		SoundType.AMBIENT:
			return ambient_volume
		SoundType.MUSIC:
			return music_volume
	
	return 1.0

# Обработчик окончания музыки
func _on_music_finished() -> void:
	# Можно добавить автоматическое воспроизведение следующего трека
	pass

# Установка громкости
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	update_player_volumes()

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	if music_player != null:
		music_player.volume_db = linear_to_db(music_volume * master_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	if gameplay_player != null:
		gameplay_player.volume_db = linear_to_db(sfx_volume * master_volume)
	
	for player in gameplay_players_pool:
		player.volume_db = linear_to_db(sfx_volume * master_volume)

func set_ui_volume(volume: float) -> void:
	ui_volume = clamp(volume, 0.0, 1.0)
	if ui_player != null:
		ui_player.volume_db = linear_to_db(ui_volume * master_volume)
	
	for player in ui_players_pool:
		player.volume_db = linear_to_db(ui_volume * master_volume)

func set_ambient_volume(volume: float) -> void:
	ambient_volume = clamp(volume, 0.0, 1.0)
	if ambient_player != null:
		ambient_player.volume_db = linear_to_db(ambient_volume * master_volume)

# Обновление громкости всех плееров
func update_player_volumes() -> void:
	if music_player != null:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
	if ui_player != null:
		ui_player.volume_db = linear_to_db(ui_volume * master_volume)
	if gameplay_player != null:
		gameplay_player.volume_db = linear_to_db(sfx_volume * master_volume)
	if ambient_player != null:
		ambient_player.volume_db = linear_to_db(ambient_volume * master_volume)
	
	for player in ui_players_pool:
		player.volume_db = linear_to_db(ui_volume * master_volume)
	
	for player in gameplay_players_pool:
		player.volume_db = linear_to_db(sfx_volume * master_volume)

# Воспроизведение фонового звука для времени суток
func play_ambient_for_time_of_day(time_of_day: String) -> void:
	var sound_name = "ambient_day"
	
	if time_of_day == "night" or time_of_day == "evening":
		sound_name = "ambient_night"
	
	play_sound(sound_name, SoundType.AMBIENT)
