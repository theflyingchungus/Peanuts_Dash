extends Node2D
@onready var level_label: Label = $HUD/Panel/LevelLabel

var level: int = 1
var current_level_root: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Setup the level
	current_level_root = get_node("LevelRoot")
	_load_level(level)

# ----------------------
# LEVEL MANAGEMENT
# ----------------------

func _load_level(level_number: int) -> void:
	if current_level_root:
		current_level_root.queue_free()
		
	# Change Level
	var level_path = "res://level_scenes/level%s.tscn" % level_number
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	_setup_level(current_level_root)

func _setup_level(level_root: Node) -> void:
	# Connect Peanuts
	var peanuts = level_root.get_node_or_null("Peanuts")
	
	# Connect Exit
	var exit = level_root.get_node_or_null("Exit")
	if exit:
		exit.body_entered.connect(_on_exit_body_entered)
	
	# Connect Entry
	var entry = level_root.get_node_or_null("Entry")
	if entry:
		entry.body_entered.connect(_on_entry_body_entered)
	
	level_label.text = "LEVEL: %s" % level
	
# ----------------------
# SIGNAL HANDLERS
# ----------------------

func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		level += 1
		body.lock_movement()
		call_deferred("_load_level", level)
		GameState.set_spawn_point("FromPreviousLevel")

func _on_entry_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		level -= 1
		body.lock_movement()
		call_deferred("_load_level", level)
		GameState.set_spawn_point("FromNextLevel")
