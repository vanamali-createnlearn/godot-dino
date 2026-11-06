extends Node

const DASH_ACTION: StringName = &"dash"

@export var dash_speed: float = 750.0
@export var dash_duration: float = 0.20
@export var dash_cooldown: float = 0.70

@onready var player: CharacterBody2D = get_parent()

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _dash_direction: float = 1.0


func _ready() -> void:
	_setup_dash_input()


func _setup_dash_input() -> void:
	# Create the dash action if it doesn't exist.
	if not InputMap.has_action(DASH_ACTION):
		InputMap.add_action(DASH_ACTION)

	# Create a Left Shift keyboard event.
	var shift_event := InputEventKey.new()
	shift_event.physical_keycode = KEY_SHIFT
	shift_event.location = KEY_LOCATION_LEFT

	# Avoid adding the same key binding twice.
	if not InputMap.action_has_event(DASH_ACTION, shift_event):
		InputMap.action_add_event(DASH_ACTION, shift_event)

	print("Dash input configured: Left Shift")


func try_start_dash(direction: float) -> bool:
	if _is_dashing:
		return false

	if _cooldown_timer > 0.0:
		return false

	if is_zero_approx(direction):
		return false

	_dash_direction = signf(direction)
	_dash_timer = dash_duration
	_cooldown_timer = dash_cooldown
	_is_dashing = true

	player.velocity = Vector2(
		_dash_direction * dash_speed,
		0.0
	)

	print("DASH STARTED!")

	return true


func update_dash(delta: float) -> bool:
	_cooldown_timer = maxf(
		_cooldown_timer - delta,
		0.0
	)

	if not _is_dashing:
		return false

	_dash_timer -= delta

	player.velocity = Vector2(
		_dash_direction * dash_speed,
		0.0
	)

	if _dash_timer <= 0.0:
		_is_dashing = false
		print("DASH ENDED!")

	return true


func is_dashing() -> bool:
	return _is_dashing


func get_dash_direction() -> float:
	return _dash_direction
