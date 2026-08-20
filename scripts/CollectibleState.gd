extends Node

var collected_ids: Dictionary = {}  # acts as a Set — keys are peanut_ids, value unused

func mark_collected(id: String):
	collected_ids[id] = true

func is_collected(id: String) -> bool:
	return collected_ids.has(id)
