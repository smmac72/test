extends Control

# Сигналы
signal loading_completed

# Компоненты
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var label: Label = $VBoxContainer/Label

# Состояние загрузки
var progress: float = 0.0
var target_progress: float = 0.0
var loading_steps: Array = []
var current_step: int = 0

func _ready() -> void:
	# Инициализация компонентов
	progress_bar.value = 0
	
	# Задаем этапы загрузки
	loading_steps = [
		"Инициализация системы...",
		"Загрузка конфигураций...",
		"Подготовка производства...",
		"Инициализация клиентов...",
		"Загрузка ресурсов...",
		"Завершение загрузки..."
	]
	
	# Запускаем процесс загрузки
	start_loading()

func _process(delta: float) -> void:
	# Плавное обновление прогресс-бара
	if progress < target_progress:
		progress += delta * 0.5  # Скорость заполнения
		progress_bar.value = progress * 100
	
	# Проверка завершения текущего шага
	if progress >= target_progress && current_step < loading_steps.size():
		_next_loading_step()

# Запуск процесса загрузки
func start_loading() -> void:
	# Сбрасываем прогресс
	progress = 0.0
	target_progress = 0.0
	current_step = 0
	
	# Запускаем первый шаг
	_next_loading_step()

# Переход к следующему шагу загрузки
func _next_loading_step() -> void:
	if current_step >= loading_steps.size():
		# Завершаем загрузку
		_complete_loading()
		return
	
	# Обновляем текст и целевой прогресс
	label.text = loading_steps[current_step]
	target_progress = float(current_step + 1) / loading_steps.size()
	
	# Увеличиваем счетчик шагов
	current_step += 1
	
	# Имитируем задержку загрузки
	await get_tree().create_timer(0.5).timeout

# Завершение загрузки
func _complete_loading() -> void:
	# Устанавливаем прогресс-бар на 100%
	progress_bar.value = 100
	
	# Отправляем сигнал о завершении
	emit_signal("loading_completed")
	
	# Немного ждем для плавности
	await get_tree().create_timer(0.5).timeout
	
	# Скрываем экран загрузки
	hide()

# Установка прогресса загрузки вручную
func set_progress(value: float, text: String = "") -> void:
	target_progress = value
	if text != "":
		label.text = text
