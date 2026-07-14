extends Node2D

@onready var player = $Player2D
@onready var exit_area = $Exit
@onready var left_button = $MobileUI/LeftButton
@onready var right_button = $MobileUI/RightButton
@onready var jump_button = $MobileUI/JumpButton
@onready var restart_button = $MobileUI/RestartButton

const START_POSITION = Vector2(120, 360)

func _ready():
	_remove_defeated_enemies()
	_place_player()
	exit_area.body_entered.connect(_on_exit_body_entered)
	left_button.button_down.connect(func(): Input.action_press("ui_left"))
	left_button.button_up.connect(func(): Input.action_release("ui_left"))
	right_button.button_down.connect(func(): Input.action_press("ui_right"))
	right_button.button_up.connect(func(): Input.action_release("ui_right"))
	jump_button.button_down.connect(func(): Input.action_press("ui_accept"))
	jump_button.button_up.connect(func(): Input.action_release("ui_accept"))
	restart_button.pressed.connect(GameManager.reset_run)

func _exit_tree():
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_accept")

func _place_player():
	if GameManager.returning_from_duel:
		player.global_position = GameManager.saved_player_2d_position
		GameManager.returning_from_duel = false
	else:
		player.global_position = START_POSITION

func _remove_defeated_enemies():
	for enemy in get_tree().get_nodes_in_group("enemies_2d"):
		if GameManager.defeated_enemy_ids.has(enemy.enemy_id):
			enemy.queue_free()

func _on_exit_body_entered(body):
	if body == player and GameManager.defeated_enemy_ids.has("enemy_01"):
		print("Level complete")
