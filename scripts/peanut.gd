extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var collect_sound: AudioStreamPlayer2D = $Collect

var peanut_id: String = ""

signal collected

func _ready():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	var level_identifier = str(level_manager.level) if level_manager else "unknown"
	
	peanut_id = level_identifier + "_peanut_" + str(global_position)

	if CollectibleState.is_collected(peanut_id):
		queue_free()  # already collected — remove immediately, don't even show it
		return
	
func _on_body_entered(body: Node2D) -> void:
	animated_sprite_2d.animation = "collected"
	collected.emit()
	call_deferred("_disable_collision")
	CollectibleState.mark_collected(peanut_id)
	ScoreManager.add_point()
	collect_sound.play()

func _disable_collision() -> void:
	collision_shape_2d.disabled = true


func _on_animated_sprite_2d_animation_looped() -> void:
	if animated_sprite_2d.animation == "collected":
		queue_free()
