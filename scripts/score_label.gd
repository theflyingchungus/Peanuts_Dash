extends Label

func _ready():
	SignalBus.score_changed.connect(_on_score_changed)
	text = "SCORE: %s" % str(SignalBus.score)  # sync immediately in case score was already > 0

func _on_score_changed(_new_score):
	text = "SCORE: %s" % str(SignalBus.score)
