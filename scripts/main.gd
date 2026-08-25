extends Node2D
@onready var level_label: Label = $HUD/Panel/LevelLabel
@onready var fade: ColorRect = $HUD/Fade
@onready var pitfall_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var level: int = 8
var current_level_root: Node = null
var entry_spawn_point: String = "FromPreviousLevel"

# When game boots up, fade in.
# Assigns the new level's node as the current_level_root node, ignore when it is first game startup.

func _ready() -> void:
	fade.modulate.a = 1.0
	if current_level_root != null:
		current_level_root = get_node("LevelRoot")
	await _load_level(level, false)

# ----------------------
# LEVEL MANAGEMENT
# ----------------------

func _load_level(level_number: int, secret: bool) -> void:
	await _fade(1.0)
	
	# Deletes the current node level.
	
	if current_level_root:
		current_level_root.queue_free()
	
	# Identifies the exact level scene file path based on the current level value and if secret is triggered.
	# Loads the corresponding level scene and instantiate the scene as Main's child node.
	# Rename it to "LevelRoot" so the node can be assigned as the current_level_root node.
	
	var level_path = "res://level_scenes/level%s%s.tscn" % [level_number, "secret" if secret else ""]
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	_setup_level(current_level_root)

	await _fade(0.0)

func _setup_level(level_root: Node) -> void:
	
	# Each dict entry: node name → (level delta, spawn point name, if secret level, absolute_target_override)
	# Level delta should be:
		# 1 if player proceeds to the next level (via Exit)
		# -1 if player returns to a previous level (via Entry)
		# 0 if player visits or leaves a secret level (via Secret)
	# absolute_target_override = -1 means "use delta normally"; any other value jumps straight there
	var triggers = {
		"Exit": [1, "FromPreviousLevel", false, -1],
		"Exit2": [1, "FromPreviousLevel2", false, -1],
		"ExitSecret": [0, "FromPreviousLevel", true, -1],
		"Entry": [-1, "FromNextLevel", false, -1],
		"Entry2": [-1, "FromNextLevel2", false, -1],
		"EntrySecret": [0, "FromSecretLevel", false, -1],
		
		## Special one-off: Level 8's secret exit jumps straight to Level 10
		#"ExitToLevel10": [0, "FromLevel8SecretExit", false, 10],
		## Special one-off: Level 10's entry from that path goes straight back to Level 8
		#"EntryFromLevel8Secret": [0, "FromLevel10ViaSecretExit", false, 8],
	}
	
	# Listens to a stage transition signal, e.g. Player walks into an entry/exit door or falls into pit.
	# Once triggered, identifies the node name and sends (.bind) the respective data to the corresponding
	# signal handler function.
	
	for node_name in triggers.keys():
		var node = level_root.get_node_or_null(node_name)
		if node:
			var data = triggers[node_name]
			node.body_entered.connect(_on_level_transition.bind(data[0], data[1], data[2], data[3]))

	var pit = level_root.get_node_or_null("Pit")
	if pit:
		pit.body_entered.connect(_respawn_player)
	
	if not SignalBus.thorn_touched.is_connected(_respawn_player):
		SignalBus.thorn_touched.connect(_respawn_player)
	
	# Default camera bounds for a screen-sized level.
	# Will be overridden by in-level Camera2D nodes, if exist.
	
	var camera = level_root.find_child("Camera2D", true, false)
	var bounds = level_root.get_node_or_null("CameraBounds")
	if camera and bounds:
		camera.limit_left = bounds.limit_left
		camera.limit_right = bounds.limit_right
		camera.limit_top = bounds.limit_top
		camera.limit_bottom = bounds.limit_bottom
	
	# Level label HUD
	
	level_label.text = "LEVEL: %s" % level

# ----------------------
# SIGNAL HANDLERS
# ----------------------

# When Player walks into a level transition, calls the respective function

func _on_level_transition(body: Node2D, level_delta: int, spawn_point: String, secret: bool, target_override: int) -> void:
	if target_override != -1:
		level = target_override
	else:
		level += level_delta
	body.lock_movement()
	entry_spawn_point = spawn_point
	GameState.set_spawn_point(entry_spawn_point)
	call_deferred("_load_level", level, secret)

func _respawn_player(body: Node2D) -> void:
	body.lock_movement()
	GameState.set_spawn_point(entry_spawn_point)
	call_deferred("_load_level", level, false)
	pitfall_sound.play()


# ----------------------
# SCREEN TRANSITION VFX
# ----------------------

# Screen fade upon level transitions

func _fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 0.5)
	await tween.finished
