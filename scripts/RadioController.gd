extends Node

var stations = ["res://audio/radio1.ogg", "res://audio/radio2.ogg"]
var current_idx = 0

@onready var player = AudioStreamPlayer.new()

func _ready():
	add_child(player)
	_play_current()

func _play_current():
	player.stream = load(stations[current_idx])
	player.play()

func next_station():
	current_idx = (current_idx + 1) % stations.size()
	_play_current()
