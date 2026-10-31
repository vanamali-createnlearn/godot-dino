extends Area2D

@export var coin_value: int = 1


func _on_body_entered(body: Node2D) -> void:
	var score_manager = body.get_node_or_null("ScoreManager")

	if score_manager != null and score_manager.has_method("add_score"):
		score_manager.call("add_score", coin_value)
		queue_free()
