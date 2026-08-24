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
	
	if peanut_butter_id.match("1_peanut_butter*"): # Replace number with level of power-up location
		Global.grant_power_up(0) # JUMP
	if peanut_butter_id.match("3_peanut_butter*"):
		Global.grant_power_up(1) # DASH

func _disable_collision() -> void:
	collision_shape_2d.disabled = true


func _on_animated_sprite_2d_animation_looped() -> void:
	if animated_sprite_2d.animation == "collected":
		queue_free()
