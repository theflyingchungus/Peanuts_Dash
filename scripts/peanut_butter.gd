extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var collect_sound: AudioStreamPlayer2D = $Collect

var peanut_butter_id: String = ""

func _ready():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	var level_identifier = str(level_manager.level) if level_manager else "unknown"
	
	peanut_butter_id = level_identifier + "_peanut_butter_" + str(global_position)

	if CollectibleState.is_collected(peanut_butter_id):
		queue_free()  # already collected — remove immediately, don't even show it
		return
	
func _on_body_entered(_body: Node2D) -> void:
	animated_sprite_2d.animation = "collected"
	call_deferred("_disable_collision")
	CollectibleState.mark_collected(peanut_butter_id)
	ScoreManager.add_point_10()
	collect_sound.play()
	
	# Set the dict keys as the level of the respective power-up locations
	var power_up_level_loc: Dictionary[int, int] = {
		2: Global.PowerUp.JUMP,
		5: Global.PowerUp.DASH,
		7: Global.PowerUp.AIR_DASH,
		8: Global.PowerUp.DOUBLE_JUMP,
		10: Global.PowerUp.DOUBLE_DASH,
	}
	var search_id: int = int(peanut_butter_id.split("_")[0]) # Identify the level in the id
	
	for level in power_up_level_loc:
		if search_id == level:
			Global.grant_power_up(power_up_level_loc[level])

func _disable_collision() -> void:
	collision_shape_2d.disabled = true

func _on_animated_sprite_2d_animation_looped() -> void:
	if animated_sprite_2d.animation == "collected":
		queue_free()
