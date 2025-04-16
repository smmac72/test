extends Node

@export var seconds_per_game_minute: float = 1.0
var game_minutes : int = 480 # 08:00

signal minute_passed(game_minutes)

var _accum := 0.0

func _process(delta):
	_accum += delta
	if _accum >= seconds_per_game_minute:
		_accum -= seconds_per_game_minute
		game_minutes += 1
		emit_signal("minute_passed", game_minutes)
