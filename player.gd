extends CharacterBody2D

@export var speed: float = 220.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(_delta: float) -> void:
    var direction := 0.0

    if Input.is_physical_key_pressed(KEY_A):
        direction -= 1.0

    if Input.is_physical_key_pressed(KEY_D):
        direction += 1.0

    velocity.x = direction * speed
    move_and_slide()

    if direction == 0:
        animated_sprite.play("idle")
    else:
        animated_sprite.play("run")
        animated_sprite.flip_h = direction < 0
