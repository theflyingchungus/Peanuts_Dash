extends Node

var score: int = 0

signal score_changed(new_score)

func add_point():
	score += 1
	score_changed.emit(score)
	
func add_point_10():
	score += 10
	score_changed.emit(score)
