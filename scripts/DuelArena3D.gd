extends Node3D

var player_hp := 3
var enemy_hp := 3
var enemy_state := "Preparing Attack"
var state_index := 0

const ENEMY_STATES := ["Preparing Attack", "Guarding", "Open"]

@onready var player_hp_label: Label = $UI/PlayerHPLabel
@onready var enemy_hp_label: Label = $UI/EnemyHPLabel
@onready var enemy_state_label: Label = $UI/EnemyStateLabel
@onready var attack_button: Button = $UI/AttackButton
@onready var guard_button: Button = $UI/GuardButton
@onready var state_timer: Timer = $StateTimer

func _ready() -> void:
	attack_button.pressed.connect(_on_attack_pressed)
	guard_button.pressed.connect(_on_guard_pressed)
	state_timer.timeout.connect(_on_state_timer_timeout)
	state_timer.start()
	_update_ui()

func _on_state_timer_timeout() -> void:
	state_index = (state_index + 1) % ENEMY_STATES.size()
	enemy_state = ENEMY_STATES[state_index]
	_update_ui()

func _on_attack_pressed() -> void:
	if enemy_state == "Open":
		enemy_hp -= 1
	else:
		player_hp -= 1
	_check_duel_end()
	_update_ui()

func _on_guard_pressed() -> void:
	if enemy_state == "Preparing Attack":
		_update_ui()
	else:
		_update_ui()

func _check_duel_end() -> void:
	if enemy_hp <= 0:
		GameManager.finish_duel_win()
	elif player_hp <= 0:
		GameManager.finish_duel_lose()

func _update_ui() -> void:
	player_hp_label.text = "Player HP: %d" % player_hp
	enemy_hp_label.text = "Enemy HP: %d" % enemy_hp
	enemy_state_label.text = "Enemy State: %s" % enemy_state
