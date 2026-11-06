
extends Node

@export var wall_probe_width: float = 16.0
@export var wall_probe_height_ratio: float = 0.8
@export var wall_probe_overlap: float = 6.0

@export var wall_jump_horizontal_speed: float = 420.0
@export var wall_jump_vertical_speed: float = 520.0
@export var regrab_delay: float = 0.22

@onready var player: CharacterBody2D = get_parent()

var _is_clinging: bool = false
var _cling_normal: Vector2 = Vector2.ZERO
var _regrab_timer: float = 0.0

var _probe_shape: RectangleShape2D
var _left_probe_offset: Vector2
var _right_probe_offset: Vector2

var _debug_check_printed: bool = false


func _ready() -> void:
	var collision_shape: CollisionShape2D = player.get_node("CollisionShape2D")

	if collision_shape.shape == null:
		push_error("Player CollisionShape2D has no shape assigned!")
		return

	# Calculate the player's collision dimensions.
	var shape_rect: Rect2 = collision_shape.shape.get_rect()

	var half_width: float = (
		shape_rect.size.x
		* 0.5
		* absf(collision_shape.scale.x)
	)

	var half_height: float = (
		shape_rect.size.y
		* 0.5
		* absf(collision_shape.scale.y)
	)

	# Create rectangular detection probes.
	_probe_shape = RectangleShape2D.new()

	_probe_shape.size = Vector2(
		wall_probe_width,
		maxf(half_height * 2.0 * wall_probe_height_ratio, 20.0)
	)

	# Position the probes slightly inside the player's edges.
	_left_probe_offset = collision_shape.position + Vector2(
		-half_width - wall_probe_width * 0.5 + wall_probe_overlap,
		0.0
	)

	_right_probe_offset = collision_shape.position + Vector2(
		half_width + wall_probe_width * 0.5 - wall_probe_overlap,
		0.0
	)

	print("Wall Grab Controller ready.")
	print("Wall probe size: ", _probe_shape.size)


func update_wall_state(delta: float, grapple_active: bool) -> void:
	_regrab_timer = maxf(_regrab_timer - delta, 0.0)

	# Cannot cling while grappling or standing on the ground.
	if grapple_active or player.is_on_floor():
		_is_clinging = false
		_cling_normal = Vector2.ZERO
		_debug_check_printed = false
		return

	# E must be held.
	if not Input.is_physical_key_pressed(KEY_E):
		_is_clinging = false
		_cling_normal = Vector2.ZERO
		_debug_check_printed = false
		return

	# Prevent immediate reattachment after a wall jump.
	if _regrab_timer > 0.0:
		_is_clinging = false
		_cling_normal = Vector2.ZERO
		return

	_cling_normal = _find_climbable_wall_normal()
	_is_clinging = _cling_normal != Vector2.ZERO

	if _is_clinging:
		player.velocity = Vector2.ZERO


func _find_climbable_wall_normal() -> Vector2:
	var left_found: bool = _check_wall_probe(
		_left_probe_offset,
		"LEFT"
	)

	var right_found: bool = _check_wall_probe(
		_right_probe_offset,
		"RIGHT"
	)

	# A wall on the left pushes the player to the right.
	# A wall on the right pushes the player to the left.
	if left_found and not right_found:
		return Vector2.RIGHT

	if right_found and not left_found:
		return Vector2.LEFT

	# If both walls are detected, use the player's input.
	if left_found and right_found:
		if Input.is_physical_key_pressed(KEY_A):
			return Vector2.RIGHT

		if Input.is_physical_key_pressed(KEY_D):
			return Vector2.LEFT

		if _cling_normal != Vector2.ZERO:
			return _cling_normal

		return Vector2.RIGHT

	return Vector2.ZERO


func _check_wall_probe(
	local_offset: Vector2,
	probe_name: String
) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()

	query.shape = _probe_shape

	var probe_transform: Transform2D = player.global_transform
	probe_transform.origin = player.to_global(local_offset)

	query.transform = probe_transform
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [player.get_rid()]

	var space_state := player.get_world_2d().direct_space_state

	var results: Array[Dictionary] = space_state.intersect_shape(
		query,
		16
	)

	var found_climbable: bool = false
	var detected_objects: Array[String] = []

	for result: Dictionary in results:
		var collider: Object = result.get("collider")

		if collider is Node:
			var is_climbable: bool = collider.is_in_group(
				"climbable_walls"
			)

			detected_objects.append(
				str(collider.name, " | Climbable: ", is_climbable)
			)

			if is_climbable:
				found_climbable = true

	if not _debug_check_printed:
		print(probe_name, " probe: ", detected_objects)

	return found_climbable


func is_clinging() -> bool:
	return _is_clinging


func get_cling_normal() -> Vector2:
	return _cling_normal


func is_wall_jump_locked() -> bool:
	return _regrab_timer > 0.0


func perform_wall_jump() -> void:
	if not _is_clinging:
		return

	# Launch away from the wall and upward.
	player.velocity = Vector2(
		_cling_normal.x * wall_jump_horizontal_speed,
		-wall_jump_vertical_speed
	)

	_is_clinging = false
	_cling_normal = Vector2.ZERO

	_regrab_timer = regrab_delay
	_debug_check_printed = false

	print("WALL JUMP!")
