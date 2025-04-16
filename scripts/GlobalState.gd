extends Node

signal money_changed(value)
signal reputation_changed(value)
signal day_passed(current_day)

var _money: int = 1_000
var _rep:   int = 0

var money: int:
	get:         return _money
	set(value):  
		_money = value
		money_changed.emit(_money)
var reputation: int:
	get:         return _rep
	set(value):  
		_rep = value
		reputation_changed.emit(_rep)

var current_day: int = 1
func _set_money(value:int):
	money = value
	emit_signal("money_changed", money)

func _set_rep(value:int):
	reputation = value
	emit_signal("reputation_changed", reputation)

func next_day():
	current_day += 1
	emit_signal("day_passed", current_day)
