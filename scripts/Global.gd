extends Node


enum PowerUp {
	JUMP,
	DOUBLE_JUMP,
	DASH,
	DOUBLE_DASH,
	AIR_DASH,
}

signal power_up_granted(id: int)

var power_ups := {
	PowerUp.JUMP: false,
	PowerUp.DOUBLE_JUMP: false,
	PowerUp.DASH: false,
	PowerUp.DOUBLE_DASH: false,
	PowerUp.AIR_DASH: false,
}


func has_power_up(id: int) -> bool:
	return power_ups.get(id, false)


func grant_power_up(id: int) -> void:
	if power_ups.get(id, false):
		return # already owned, don't re-fire the signal
	power_ups[id] = true
	power_up_granted.emit(id)


# --- Save / load helpers ---
# Dictionary keys are enum ints, which serialize cleanly to JSON.

func get_save_data() -> Dictionary:
	return power_ups.duplicate()


func load_save_data(data: Dictionary) -> void:
	for key in data.keys():
		# JSON always deserializes dictionary keys as strings, so if you're
		# loading from a JSON file you'll need to convert back to int:
		# power_ups[int(key)] = data[key]
		power_ups[key] = data[key]
