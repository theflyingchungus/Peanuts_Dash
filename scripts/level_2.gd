extends Node2D

@onready var player = $Player
@onready var spawn_points = $SpawnPoints

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var spawn_name = GameState.next_spawn_point
	if spawn_points.has_node(spawn_name):
		player.global_position = spawn_points.get_node(spawn_name).global_position
	else:
		# Fallback so Player never spawn at (0,0) by accident
		player.global_position = spawn_points.get_node("FromPreviousLevel").global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
