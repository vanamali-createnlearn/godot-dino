extends Node

@onready var player: CharacterBody2D = get_parent()
@onready var rope: Line2D = $Rope
@onready var grapple_physics: GrapplePhysics = $GrapplePhysics

var active_target: GrappleBlock = null


func _ready() -> void:
	rope.visible = false
	rope.width = 5.0
	rope.default_color = Color(0.15, 0.85, 1.0, 1.0)
	rope.antialiased = true

	# Draw the rope in front of the level geometry.
	rope.z_index = 10


func is_grappling() -> bool:
	return grapple_physics.is_grappling()


func apply_physics_before_move(delta: float) -> void:
	grapple_physics.apply_before_move(delta)


func apply_physics_after_move() -> void:
	grapple_physics.apply_after_move()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				attach_grapple()
			else:
				detach_grapple()


func attach_grapple() -> void:
	if is_grappling():
		return

	var nearest_block: GrappleBlock = null
	var nearest_distance: float = INF

	for block in get_tree().get_nodes_in_group("grapple_blocks"):
		if not block.is_grappleable:
			continue

		var aim_icon: Sprite2D = block.get_node_or_null("AimIcon")

		if aim_icon == null or not bool(aim_icon.get("is_active")):
			continue

		var distance: float = player.global_position.distance_to(
			block.get_grapple_anchor()
		)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_block = block

	if nearest_block == null:
		print("No grapple target in range!")
		return

	active_target = nearest_block
	grapple_physics.start_grapple(nearest_block)

	rope.visible = true

	print("GRAPPLE ATTACHED!")


func detach_grapple() -> void:
	if not is_grappling():
		return

	grapple_physics.stop_grapple()

	active_target = null
	rope.visible = false
	rope.clear_points()

	print("GRAPPLE RELEASED!")


func _process(_delta: float) -> void:
	if not is_grappling():
		return

	if not is_instance_valid(active_target):
		active_target = null
		rope.visible = false
		rope.clear_points()
		return

	# Start the rope slightly above the player's center.
	var player_position: Vector2 = rope.to_local(
		player.global_position + Vector2(0, -10)
	)

	var anchor_position: Vector2 = rope.to_local(
		active_target.get_grapple_anchor()
	)

	rope.clear_points()
	rope.add_point(player_position)
	rope.add_point(anchor_position)
