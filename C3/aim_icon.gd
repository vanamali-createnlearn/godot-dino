extends Sprite2D

@export var activation_distance: float = 400.0
@export var fade_duration: float = 0.15
@export var pulse_scale: float = 1.12

@onready var grapple_block: GrappleBlock = get_parent()

var player: CharacterBody2D
var base_scale: Vector2
var is_active: bool = false

var fade_tween: Tween
var pulse_tween: Tween

var debug_timer: float = 0.0


func _ready() -> void:
	base_scale = scale
	visible = false
	modulate.a = 0.0

	player = get_tree().current_scene.get_node_or_null("Player")

	if player == null:
		print("DEBUG: Player not found! Check the Player group.")


func _process(delta: float) -> void:

	# Print distance information every 3 seconds.
	debug_timer += delta

	if debug_timer >= 3.0:
		debug_timer = 0.0

		if player == null:
			print("DEBUG: Player reference is null.")
		else:
			var icon_distance := player.global_position.distance_to(
				global_position
			)

			var block_distance := player.global_position.distance_to(
				grapple_block.global_position
			)

			var anchor_distance := player.global_position.distance_to(
				grapple_block.get_grapple_anchor()
			)

			print(
				"DEBUG | Icon: ", round(icon_distance),
				" px | Block: ", round(block_distance),
				" px | Anchor: ", round(anchor_distance),
				" px | Activation: ", activation_distance,
				" px | Grappleable: ", grapple_block.is_grappleable
			)

	# Check activation distance.
	if player == null:
		return

	var distance := player.global_position.distance_to(
		grapple_block.get_grapple_anchor()
	)

	var should_show := (
		grapple_block.is_grappleable
		and distance <= activation_distance
	)

	if should_show:
		show_icon()
	else:
		hide_icon()


func show_icon() -> void:
	if is_active:
		return

	is_active = true

	if fade_tween != null:
		fade_tween.kill()

	if pulse_tween != null:
		pulse_tween.kill()

	visible = true
	scale = base_scale

	fade_tween = create_tween()
	fade_tween.tween_property(
		self, "modulate:a", 1.0, fade_duration
	)

	pulse_tween = create_tween().set_loops()

	pulse_tween.tween_property(
		self, "scale", base_scale * pulse_scale, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	pulse_tween.tween_property(
		self, "scale", base_scale, 0.65
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func hide_icon() -> void:
	if not is_active:
		return

	is_active = false

	if fade_tween != null:
		fade_tween.kill()

	if pulse_tween != null:
		pulse_tween.kill()

	scale = base_scale

	fade_tween = create_tween()
	fade_tween.tween_property(
		self, "modulate:a", 0.0, fade_duration
	)
	fade_tween.tween_callback(_finish_hiding)


func _finish_hiding() -> void:
	if not is_active:
		visible = false
