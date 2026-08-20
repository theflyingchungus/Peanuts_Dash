extends Node

var score: int = 0

signal score_changed(new_score)

func add_point():
	score += 1
	score_changed.emit(score)
