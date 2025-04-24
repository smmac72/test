extends Node

# Сигналы для обновления UI и других систем
signal money_changed(value)
signal reputation_changed(value)
signal day_passed(current_day)
signal game_over(reason)
signal game_paused(is_paused)

# Основные игровые переменные
var _money: int = 1500           # Начальные деньги
var _reputation: int = 100       # Начальная репутация
var _is_paused: bool = false     # Пауза игры
var current_day: int = 0         # Текущий день
var game_speed: float = 1.0      # Множитель скорости игры

# Свойства с геттерами и сеттерами
var money: int:
	get: return _money
	set(value):  
		_money = value
		money_changed.emit(_money)

var reputation: int:
	get: return _reputation
	set(value):  
		_reputation = value
		reputation_changed.emit(_reputation)

# Статистика игры
var stats = {
	"products_made": {},         # id продукта -> количество
	"sales": {},                 # id продукта -> количество
	"total_income": 0,           # Общий доход
	"total_expenses": 0,         # Общие расходы
	"fines_paid": 0,             # Уплаченные штрафы
	"customers_served": 0,       # Обслуженные клиенты
	"failed_orders": 0           # Проваленные заказы
}

# Флаги состояния
var has_debt: bool = false        # Есть ли долг
var debt_amount: int = 0          # Сумма долга
var debt_due_day: int = 0         # День платежа по долгу

func _ready() -> void:
	# Инициализация при старте игры
	pass

func next_day() -> void:
	current_day += 1
	
	# Проверка долга
	if has_debt and current_day >= debt_due_day:
		if money >= debt_amount:
			money -= debt_amount
			has_debt = false
			debt_amount = 0
		else:
			# Не можем выплатить долг - игра окончена
			game_over.emit("debt")
	
	day_passed.emit(current_day)

func set_pause(paused: bool) -> void:
	_is_paused = paused
	game_paused.emit(_is_paused)

func toggle_pause() -> void:
	set_pause(!_is_paused)

func is_paused() -> bool:
	return _is_paused

func take_loan(amount: int, duration: int = 7) -> void:
	# Получение займа
	if has_debt:
		return  # Уже есть долг
	
	money += amount
	has_debt = true
	debt_amount = int(amount * 1.2)  # 20% процентов
	debt_due_day = current_day + duration

func pay_utilities() -> bool:
	# Оплата коммунальных услуг
	var base_cost = 100
	var cost = base_cost * (1 + current_day / 10.0)  # Растет со временем
	
	if money >= cost:
		money -= cost
		stats["total_expenses"] += cost
		return true
	else:
		return false

func add_stat(category: String, key: String, value: int = 1) -> void:
	# Добавление статистики
	if !stats.has(category):
		stats[category] = {}
	
	if !stats[category].has(key):
		stats[category][key] = 0
	
	stats[category][key] += value

# Проверка игровых условий
func check_game_over() -> bool:
	# Проверяем условия проигрыша
	if money < 0:
		game_over.emit("bankruptcy")
		return true
	
	if reputation < 0:
		game_over.emit("bad_reputation")
		return true
	
	return false

# Сохранение/загрузка
func save_data() -> Dictionary:
	return {
		"money": _money,
		"reputation": _reputation,
		"current_day": current_day,
		"has_debt": has_debt,
		"debt_amount": debt_amount,
		"debt_due_day": debt_due_day,
		"stats": stats
	}

func load_data(data: Dictionary) -> void:
	if data.has("money"):
		money = data["money"]
	
	if data.has("reputation"):
		reputation = data["reputation"]
	
	if data.has("current_day"):
		current_day = data["current_day"]
	
	if data.has("has_debt"):
		has_debt = data["has_debt"]
	
	if data.has("debt_amount"):
		debt_amount = data["debt_amount"]
	
	if data.has("debt_due_day"):
		debt_due_day = data["debt_due_day"]
	
	if data.has("stats"):
		stats = data["stats"]
