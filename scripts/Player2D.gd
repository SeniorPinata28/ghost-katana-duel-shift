extends CharacterBody2D

const SPEED := 220.0
const JUMP_VELOCITY := -420.0
const GRAVITY := 980.0

@onready var player_visual: AnimatedSprite2D = $PlayerVisual

func _ready() -> void:
	player_visual.play(&"run")
	player_visual.pause()
	player_visual.frame = 0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: float) -> void:
	if abs(direction) > 0.01:
		player_visual.flip_h = direction < 0.0

	if not is_on_floor():
		player_visual.pause()
		player_visual.frame = 2
	elif abs(direction) > 0.01:
		if not player_visual.is_playing():
			player_visual.play(&"run")
	else:
		player_visual.pause()
		player_visual.frame = 0
