# PlayerCamera.gd — attach to the Camera2D node
extends Camera2D

var active_zones: Array[Area2D] = []

func push_zone(zone: Node) -> void:
	# avoid duplicate pushes if body_entered fires twice for some reason
	if zone in active_zones:
		active_zones.erase(zone)
	active_zones.append(zone)
	_apply_bounds(zone)
	
func pop_zone(zone: Node) -> void:
	if zone in active_zones:
		active_zones.erase(zone)
	if active_zones.size() > 0:
		_apply_bounds(active_zones[-1]) # most recent camera zone will prevail
	# else: no active zone — bounds stay as they were, or set a fallback here

func _apply_bounds(zone: Node) -> void:
	limit_left = zone.limit_left
	limit_top = zone.limit_top
	limit_right = zone.limit_right
	limit_bottom = zone.limit_bottom

func smoothed() -> void:
	if active_zones.size() > 1:
		limit_smoothed = true
	else:
		limit_smoothed = false
