class_name SaveManager
extends Node

signal save_completed
signal load_completed
signal save_failed(error_message)
signal load_failed(error_message)

# Список регистрированных систем для сохранения
var _registered_systems: Dictionary = {}

# Путь к файлу сохранения
const SAVE_FILE_PATH: String = "user://samogon_save.json"
const WEB_SAVE_KEY: String = "samogon_save"

func _ready() -> void:
	# Инициализация при старте
	print("SaveManager: Инициализация")

# Регистрация системы для сохранения
func register_system(system_name: String, system_instance: Node) -> void:
	if not system_instance.has_method("get_save_data") or not system_instance.has_method("load_save_data"):
		push_error("SaveManager: Система %s не имеет необходимых методов get_save_data/load_save_data" % system_name)
		return
		
	_registered_systems[system_name] = system_instance
	print("SaveManager: Зарегистрирована система %s" % system_name)

# Сохранение игры
func save_game() -> bool:
	print("SaveManager: Начато сохранение игры")
	
	# Собираем данные от всех зарегистрированных систем
	var save_data: Dictionary = {}
	
	for system_name in _registered_systems:
		var system = _registered_systems[system_name]
		if is_instance_valid(system) and system.has_method("get_save_data"):
			save_data[system_name] = system.get_save_data()
		else:
			push_warning("SaveManager: Не удалось получить данные от системы %s" % system_name)
	
	# Сохраняем в файл
	var result = _save_to_file(save_data)
	if result:
		emit_signal("save_completed")
		print("SaveManager: Сохранение завершено успешно")
	else:
		emit_signal("save_failed", "Не удалось записать файл сохранения")
		print("SaveManager: Ошибка сохранения")
		
	return result

# Загрузка игры
func load_game() -> bool:
	print("SaveManager: Начата загрузка игры")
	
	# Загружаем данные из файла
	var save_data = _load_from_file()
	if not save_data:
		emit_signal("load_failed", "Не удалось загрузить файл сохранения")
		print("SaveManager: Ошибка загрузки - файл не найден или поврежден")
		return false
	
	# Распределяем данные по системам
	for system_name in save_data:
		if system_name in _registered_systems:
			var system = _registered_systems[system_name]
			if is_instance_valid(system) and system.has_method("load_save_data"):
				system.load_save_data(save_data[system_name])
			else:
				push_warning("SaveManager: Система %s не может загрузить данные" % system_name)
		else:
			push_warning("SaveManager: Система %s не зарегистрирована для загрузки" % system_name)
	
	emit_signal("load_completed")
	print("SaveManager: Загрузка завершена успешно")
	return true

# Проверка наличия сохранения
func has_save() -> bool:
	if OS.has_feature("web") and Engine.has_singleton("JavaScript"):
		var JavaScript = Engine.get_singleton("JavaScript")
		var has_web_save = JavaScript.eval("""
		try {
			return localStorage.getItem('%s') ? true : false;
		} catch (e) {
			console.error('Failed to check save in localStorage:', e);
			return false;
		}
		""" % WEB_SAVE_KEY)
		
		return has_web_save
	else:
		return FileAccess.file_exists(SAVE_FILE_PATH)

# Удаление сохранения
func delete_save() -> bool:
	if OS.has_feature("web") and Engine.has_singleton("JavaScript"):
		var JavaScript = Engine.get_singleton("JavaScript")
		JavaScript.eval("""
		try {
			localStorage.removeItem('%s');
		} catch (e) {
			console.error('Failed to remove save from localStorage:', e);
		}
		""" % WEB_SAVE_KEY)
		return true
	else:
		if FileAccess.file_exists(SAVE_FILE_PATH):
			var err = DirAccess.remove_absolute(SAVE_FILE_PATH)
			return err == OK
	return false

# Внутренний метод сохранения в файл
func _save_to_file(data: Dictionary) -> bool:
	if OS.has_feature("web") and Engine.has_singleton("JavaScript"):
		var JavaScript = Engine.get_singleton("JavaScript")
		JavaScript.eval("""
		try {
			localStorage.setItem('%s', JSON.stringify(%s));
			console.log('Game saved to localStorage');
			return true;
		} catch (e) {
			console.error('Failed to save to localStorage:', e);
			return false;
		}
		""" % [WEB_SAVE_KEY, JSON.stringify(data)])
		return true
	else:
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
		if not file:
			push_error("SaveManager: Не удалось открыть файл сохранения для записи")
			return false
			
		file.store_string(JSON.stringify(data, "  "))
		file.close()
		return true

# Внутренний метод загрузки из файла
func _load_from_file() -> Variant:
	var data = null
	
	if OS.has_feature("web") and Engine.has_singleton("JavaScript"):
		var JavaScript = Engine.get_singleton("JavaScript")
		var json_str = JavaScript.eval("""
		try {
			return localStorage.getItem('%s') || '';
		} catch (e) {
			console.error('Failed to load from localStorage:', e);
			return '';
		}
		""" % WEB_SAVE_KEY)
		
		if json_str and json_str != "":
			var json = JSON.new()
			var error = json.parse(json_str)
			if error == OK:
				data = json.get_data()
				if typeof(data) != TYPE_DICTIONARY:
					push_error("SaveManager: Загруженные данные имеют неверный формат")
					return null
			else:
				push_error("SaveManager: Ошибка при парсинге JSON: " + json.get_error_message())
				return null
	else:
		if not FileAccess.file_exists(SAVE_FILE_PATH):
			return null
			
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if not file:
			push_error("SaveManager: Не удалось открыть файл сохранения для чтения")
			return null
			
		var json_str = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_str)
		if error == OK:
			data = json.get_data()
			if typeof(data) != TYPE_DICTIONARY:
				push_error("SaveManager: Загруженные данные имеют неверный формат")
				return null
		else:
			push_error("SaveManager: Ошибка при парсинге JSON: " + json.get_error_message())
			return null
	
	return data
