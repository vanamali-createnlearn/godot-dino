
extends Node
class_name GrapplePhysics

@export var player: CharacterBody2D

# Reel-in settings
@export_range(0.4, 0.9, 0.05) var target_rope_ratio: float = 0.65
@export var minimum_rope_length: float = 110.0
@export var reel_speed: float = 500.0

# Swing settings
@export var swing_start_impulse: float = 420.0
@export var rope_tolerance: float = 3.0

# Release settings
@export var release_min_horizontal_speed: float = 450.0
@export var release_max_horizontal_speed: float = 900.0
@export var release_upward_speed: float = 320.0
@export var release_momentum_bonus: float = 0.25

var active_target: GrappleBlock = null

var rope_length: float = 0.0
var target_rope_length: float = 0.0

var is_reeling: bool = false
var last_swing_direction: float = 1.0


func is_grappling() -> bool:
	return is_instance_valid(active_target)


func start_grapple(target: GrappleBlock) -> void:
	if player == null or not is_instance_valid(target):
		return

	active_target = target

	var anchor: Vector2 = target.get_grapple_anchor()
	var offset: Vector2 = player.global_position - anchor

	# Calculate the actual initial rope length.
	rope_length = offset.length()

	if rope_length < 1.0:
		active_target = null
		return

	# Set the final rope length as a percentage
	# of the original distance.
	target_rope_length = maxf(
		rope_length * target_rope_ratio,
		minimum_rope_length
	)

	# Never extend a rope that is already shorter
	# than the minimum length.
	target_rope_length = minf(target_rope_length, rope_length)

	is_reeling = rope_length > target_rope_length + 1.0

	last_swing_direction = _get_requested_direction()

	print("GRAPPLE ATTACHED")
	print("Initial rope length: ", rope_length)
	print("Target rope length: ", target_rope_length)

	# If no reeling is necessary, begin swinging immediately.
	if not is_reeling:
		_start_swing()


func apply_before_move(delta: float) -> void:
	if not is_grappling():
		return

	var anchor: Vector2 = active_target.get_grapple_anchor()

	# Gradually shorten the rope.
	if is_reeling:
		rope_length = move_toward(
			rope_length,
			target_rope_length,
			reel_speed * delta
		)

	var offset: Vector2 = player.global_position - anchor
	var distance: float = offset.length()

	if distance < 0.001:
		return

	var radial: Vector2 = offset / distance

	# Prevent outward movement when the rope is taut.
	if distance >= rope_length - rope_tolerance:
		var radial_velocity: float = player.velocity.dot(radial)

		if radial_velocity > 0.0:
			player.velocity -= radial * radial_velocity


func apply_after_move() -> void:
	if not is_grappling():
		return

	var anchor: Vector2 = active_target.get_grapple_anchor()
	var offset: Vector2 = player.global_position - anchor

	var distance: float = offset.length()

	if distance < 0.001:
		return

	# Pull the player inward if their distance exceeds
	# the current rope length.
	if distance > rope_length:
		var radial: Vector2 = offset / distance
		var excess_distance: float = distance - rope_length

		player.move_and_collide(-radial * excess_distance)

	# Recalculate after the correction.
	offset = player.global_position - anchor
	distance = offset.length()

	if distance < 0.001:
		return

	var radial: Vector2 = offset / distance

	# Remove velocity that would stretch a taut rope.
	if distance >= rope_length - rope_tolerance:
		var radial_velocity: float = player.velocity.dot(radial)

		if radial_velocity > 0.0:
			player.velocity -= radial * radial_velocity

	# Update the last horizontal swing direction.
	if absf(player.velocity.x) > 25.0:
		last_swing_direction = signf(player.velocity.x)

	# Once the rope reaches its target length,
	# stop reeling and start the pendulum swing.
	if is_reeling and rope_length <= target_rope_length + 0.5:
		rope_length = target_rope_length
		is_reeling = false

		_start_swing()


func _start_swing() -> void:
	if not is_grappling():
		return

	var anchor: Vector2 = active_target.get_grapple_anchor()
	var radial: Vector2 = (
		player.global_position - anchor
	).normalized()

	# Get a direction perpendicular to the rope.
	var tangent: Vector2 = Vector2(-radial.y, radial.x)

	var direction: float = _get_requested_direction()

	# Orient the tangent toward the chosen horizontal direction.
	if absf(tangent.x) > 0.05:
		if signf(tangent.x) != direction:
			tangent = -tangent
	else:
		tangent = Vector2(direction, 0.0)

	last_swing_direction = direction

	# Give the pendulum an initial push.
	player.velocity += tangent.normalized() * swing_start_impulse

	print("SWING STARTED")


func _get_requested_direction() -> float:
	if Input.is_physical_key_pressed(KEY_A):
		return -1.0

	if Input.is_physical_key_pressed(KEY_D):
		return 1.0

	if absf(player.velocity.x) > 20.0:
		return signf(player.velocity.x)

	return 1.0


func stop_grapple() -> void:
	if not is_grappling():
		return

	var anchor: Vector2 = active_target.get_grapple_anchor()
	var offset: Vector2 = player.global_position - anchor

	# How far toward the left or right extreme is the player?
	var amplitude: float = clampf(
		absf(offset.x) / maxf(rope_length, 1.0),
		0.0,
		1.0
	)

	# Determine launch direction from which side of
	# the anchor the player is currently on.
	var launch_direction: float = signf(offset.x)

	# If almost directly below the anchor, use the
	# current swing direction instead.
	if absf(offset.x) < 12.0:
		launch_direction = signf(player.velocity.x)

		if launch_direction == 0.0:
			launch_direction = last_swing_direction

	# More horizontal displacement means a stronger launch.
	var horizontal_speed: float = lerpf(
		release_min_horizontal_speed,
		release_max_horizontal_speed,
		amplitude
	)

	# Retain some of the momentum already accumulated.
	horizontal_speed += (
		absf(player.velocity.x) * release_momentum_bonus
	)

	player.velocity.x = launch_direction * horizontal_speed

	# Give the player enough upward velocity to clear platforms.
	player.velocity.y = minf(
		player.velocity.y,
		-release_upward_speed
	)

	print("GRAPPLE RELEASED")
	print("Swing amplitude: ", amplitude)
	print("Launch direction: ", launch_direction)
	print("Launch velocity: ", player.velocity)

	active_target = null
	rope_length = 0.0
	target_rope_length = 0.0
	is_reeling = false
