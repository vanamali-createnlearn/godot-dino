extends StaticBody2D
class_name GrappleBlock

@export var is_grappleable: bool = true

@onready var anchor_point: Marker2D = $AnchorPoint


func _ready() -> void:
	add_to_group("grapple_blocks")


func get_grapple_anchor() -> Vector2:
	return anchor_point.global_position
