# RadioController.gd
extends Node

var stations: Array[String] = [
	"res://audio/radio/mikhail-muromskii-tancy-na-molberte.mp3",
]

var current_index := 0
var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)

func next_station() -> void:
	current_index = (current_index + 1) % stations.size()
	var stream = load(stations[current_index]) as AudioStream
	player.stream = stream
	player.play()
