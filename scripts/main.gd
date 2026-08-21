extends Node2D
@onready var level_label: Label = $HUD/Panel/LevelLabel
@onready var fade: ColorRect = $HUD/Fade

var level: int = 9
var current_level_root: Node = null
var entry_spawn_point: String = "FromPreviousLevel"

func _ready() -> void:
	fade.modulate.a = 1.0
	current_level_root = get_node("LevelRoot")
	await _load_level(level, false)

# ----------------------
# LEVEL MANAGEMENT
# ----------------------

func _load_level(level_number: int, secret: bool) -> void:
	await _fade(1.0)
	
	if current_level_root:
		current_level_root.queue_free()
		
	var level_path = "res://level_scenes/level%s%s.tscn" % [level_number, "secret" if secret else ""]
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	_setup_level(current_level_root)
	
	await _fade(0.0)

func _setup_level(level_root: Node) -> void:
	# Each entry: node name → (level delta, spawn point name, goes to secret level)
	var triggers = {
		"Exit": [1, "FromPreviousLevel", false],
		"Exit2": [1, "FromPreviousLevel2", false],
		"ExitSecret": [0, "FromPreviousLevel", true],
		"Entry": [-1, "FromNextLevel", false],
		"Entry2": [-1, "FromNextLevel2", false],
		"EntrySecret": [0, "FromSecretLevel", false],
		# Special one-off: Level 8's secret exit jumps straight to Level 10
		#"ExitToLevel10": [0, "FromLevel8SecretExit", false, 10],
		# Special one-off: Level 10's entry from that path goes straight back to Level 8
		#"EntryFromLevel8Secret": [0, "FromLevel10ViaSecretExit", false, 8],
	}
	
	for node_name in triggers.keys():
		var node = level_root.get_node_or_null(node_name)
		if node:
			var data = triggers[node_name]
			node.body_entered.connect(_on_level_transition.bind(data[0], data[1], data[2]))
	
	var pit = level_root.get_node_or_null("Pit")
	if pit:
		pit.body_entered.connect(_on_pit_body_entered)
	
	var camera = level_root.find_child("Camera2D", true, false)
	var bounds = level_root.get_node_or_null("CameraBounds")
	if camera and bounds:
		camera.limit_left = bounds.limit_left
		camera.limit_right = bounds.limit_right
		camera.limit_top = bounds.limit_top
		camera.limit_bottom = bounds.limit_bottom
	
	level_label.text = "LEVEL: %s" % level

func _fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 0.5)
	await tween.finished

# ----------------------
# SIGNAL HANDLERS
# ----------------------

func _on_level_transition(body: Node2D, level_delta: int, spawn_point: String, secret: bool) -> void:
	if body.name == "Player":
		level += level_delta
		body.lock_movement()
		entry_spawn_point = spawn_point
		GameState.set_spawn_point(entry_spawn_point)
		call_deferred("_load_level", level, secret)

func _on_pit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.lock_movement()
		GameState.set_spawn_point(entry_spawn_point)
		call_deferred("_load_level", level, false)
