# CameraZone.gd — attach to an Area2D
extends Area2D

@export var limit_left: int
@export var limit_top: int
@export var limit_right: int
@export var limit_bottom: int

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var camera = body.find_child("Camera2D", true, false)
	if camera:
		camera.limit_left = limit_left
		camera.limit_top = limit_top
		camera.limit_right = limit_right
		camera.limit_bottom = limit_bottom
