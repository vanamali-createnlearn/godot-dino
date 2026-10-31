extends Node

signal score_changed(new_score: int)

var score: int = 0


func add_score(amount: int) -> void:
	score += amount

	print("Score: ", score)

	score_changed.emit(score)
