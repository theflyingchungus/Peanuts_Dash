extends Area2D

func _on_body_entered(body: Node2D) -> void:
	SignalBus.thorn_touched.emit(body) 
