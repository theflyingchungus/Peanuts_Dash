extends Node

signal thorn_touched
signal score_changed(new_score)

var score: int = 0

func add_point():
	score += 1
	score_changed.emit(score)
	
func add_point_10():
	score += 10
	score_changed.emit(score)
