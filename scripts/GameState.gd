extends Node

var next_spawn_point: String = "FromStart"  # default fallback

func set_spawn_point(spawn_name: String):
	next_spawn_point = spawn_name
	
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
