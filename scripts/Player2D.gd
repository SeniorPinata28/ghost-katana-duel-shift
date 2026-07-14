extends CharacterBody2D

const SPEED = 220.0
const JUMP_VELOCITY = -420.0
const GRAVITY = 980.0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()
