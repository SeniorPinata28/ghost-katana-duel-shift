extends Node2D

@onready var player: CharacterBody2D = $Player2D
@onready var exit_area: Area2D = $Exit
@onready var left_button: Button = $MobileUI/LeftButton
@onready var right_button: Button = $MobileUI/RightButton
@onready var jump_button: Button = $MobileUI/JumpButton
@onready var dash_button: Button = $MobileUI/DashButton
@onready var melee_button: Button = $MobileUI/MeleeButton
@onready var shoot_button: Button = $MobileUI/ShootButton
@onready var berserk_button: Button = $MobileUI/BerserkButton
@onready var restart_button: Button = $MobileUI/RestartButton
@onready var stats_label: Label = $MobileUI/StatsLabel
@onready var status_label: Label = $MobileUI/StatusLabel

const START_POSITION := Vector2(120, 360)

func _ready() -> void:
	_remove_defeated_enemies()
	_place_player()
	exit_area.body_entered.connect(_on_exit_body_entered)

	left_button.button_down.connect(func() -> void: Input.action_press("ui_left"))
	left_button.button_up.connect(func() -> void: Input.action_release("ui_left"))
	right_button.button_down.connect(func() -> void: Input.action_press("ui_right"))
	right_button.button_up.connect(func() -> void: Input.action_release("ui_right"))
	jump_button.button_down.connect(func() -> void: Input.action_press("ui_accept"))
	jump_button.button_up.connect(func() -> void: Input.action_release("ui_accept"))

	dash_button.pressed.connect(player.request_dash)
	melee_button.pressed.connect(player.melee_attack)
	shoot_button.pressed.connect(player.shoot)
	berserk_button.pressed.connect(player.activate_berserk)
	restart_button.pressed.connect(GameManager.reset_run)
	player.status_changed.connect(_on_player_status_changed)

	status_label.text = "Разрушайте блоки, победите врага и освободите пленного."

func _process(_delta: float) -> void:
	stats_label.text = "HP %d/%d   ЯРОСТЬ %d%%" % [maxi(player.health, 0), player.max_health, player.rage]
	dash_button.text = player.get_dash_text()
	berserk_button.text = player.get_berserk_text()
	berserk_button.disabled = not player.berserk_unlocked or (player.rage < 100 and not player.is_berserk())

func _exit_tree() -> void:
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_accept")

func _place_player() -> void:
	if GameManager.returning_from_duel:
		player.global_position = GameManager.saved_player_2d_position
		GameManager.returning_from_duel = false
	else:
		player.global_position = START_POSITION

func _remove_defeated_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies_2d"):
		if GameManager.defeated_enemy_ids.has(enemy.enemy_id):
			enemy.queue_free()

func _on_player_status_changed(message: String) -> void:
	status_label.text = message

func _on_exit_body_entered(body: Node2D) -> void:
	if body == player and GameManager.defeated_enemy_ids.has("enemy_01"):
		status_label.text = "Уровень пройден"
