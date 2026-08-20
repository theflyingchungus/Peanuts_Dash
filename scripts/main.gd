extends Node2D
@onready var level_label: Label = $HUD/Panel/LevelLabel
@onready var fade: ColorRect = $HUD/Fade

var level: int = 1
var current_level_root: Node = null
var entry_spawn_point: String = "FromPreviousLevel"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Setup the level
	fade.modulate.a = 1.0
	current_level_root = get_node("LevelRoot")
	await _load_level(level)

# ----------------------
# LEVEL MANAGEMENT
# ----------------------

func _load_level(level_number: int) -> void:
	# Fade out
	await _fade(1.0)
	
	if current_level_root:
		current_level_root.queue_free()
		
	# Change Level
	var level_path = "res://level_scenes/level%s.tscn" % level_number
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	_setup_level(current_level_root)
	
	# Fade in
	await _fade(0.0)

func _setup_level(level_root: Node) -> void:
	# Connect Exit
	var exit = level_root.get_node_or_null("Exit")
	if exit:
		exit.body_entered.connect(_on_exit_body_entered)
	
	# Connect Entry
	var entry = level_root.get_node_or_null("Entry")
	if entry:
		entry.body_entered.connect(_on_entry_body_entered)
		
	var pit = level_root.get_node_or_null("Pit")
	if pit:
		pit.body_entered.connect(_on_pit_body_entered)
	
	level_label.text = "LEVEL: %s" % level
	
func _fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 0.5)
	await tween.finished
	
# ----------------------
# SIGNAL HANDLERS
# ----------------------

func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		level += 1
		body.lock_movement()
		entry_spawn_point = "FromPreviousLevel"
		GameState.set_spawn_point(entry_spawn_point)
		call_deferred("_load_level", level)

func _on_entry_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		level -= 1
		body.lock_movement()
		entry_spawn_point = "FromNextLevel"
		GameState.set_spawn_point(entry_spawn_point)
		call_deferred("_load_level", level)

func _on_pit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.lock_movement()
		GameState.set_spawn_point(entry_spawn_point)
		call_deferred("_load_level", level)
