extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@export var peanut_id: String = ""  # set a unique value per peanut in the Inspector

signal collected

func _ready():
	if peanut_id == "":
		push_warning("Peanut has no unique ID assigned!")
		return

	if CollectibleState.is_collected(peanut_id):
		queue_free()  # already collected — remove immediately, don't even show it
		return
	
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		animated_sprite_2d.animation = "collected"
		collected.emit()
		call_deferred("_disable_collision")
		CollectibleState.mark_collected(peanut_id)

func _disable_collision() -> void:
	collision_shape_2d.disabled = true


func _on_animated_sprite_2d_animation_looped() -> void:
	if animated_sprite_2d.animation == "collected":
		queue_free()
