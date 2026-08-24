extends Node

var next_spawn_point: String = "FromStart"  # default fallback
var current_level: int = 0

func set_spawn_point(spawn_name: String):
	next_spawn_point = spawn_name
