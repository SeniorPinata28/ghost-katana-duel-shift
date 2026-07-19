extends Node3D

const MAX_HP := 3
const MAX_DEFENSE := 3
const DAMAGE := 1

const STATE_PREPARING: StringName = &"preparing_attack"
const STATE_GUARDING: StringName = &"guarding"
const STATE_OPEN: StringName = &"open"

var player_hp := MAX_HP
var player_defense := MAX_DEFENSE
var enemy_hp := MAX_HP
var enemy_defense := MAX_DEFENSE

var enemy_state: StringName = STATE_PREPARING
var player_guarding := false
var input_locked := false
var duel_finished := false

var player_start_position := Vector3.ZERO
var enemy_start_position := Vector3.ZERO

@onready var player_marker: MeshInstance3D = $PlayerMarker
@onready var enemy_marker: MeshInstance3D = $EnemyMarker
@onready var player_hp_label: Label = $UI/PlayerHPLabel
@onready var player_defense_label: Label = $UI/PlayerDefenseLabel
@onready var enemy_hp_label: Label = $UI/EnemyHPLabel
@onready var enemy_defense_label: Label = $UI/EnemyDefenseLabel
@onready var enemy_state_label: Label = $UI/EnemyStateLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var attack_button: Button = $UI/AttackButton
@onready var guard_button: Button = $UI/GuardButton
@onready var state_timer: Timer = $StateTimer

func _ready() -> void:
	player_start_position = player_marker.position
	enemy_start_position = enemy_marker.position

	attack_button.pressed.connect(_on_attack_pressed)
	guard_button.pressed.connect(_on_guard_pressed)
	state_timer.timeout.connect(_on_state_timer_timeout)

	status_label.text = "Враг готовит удар. Защищайтесь или рискуйте."
	_update_ui()
	state_timer.start()

func _on_state_timer_timeout() -> void:
	if duel_finished or input_locked:
		return

	if enemy_state == STATE_PREPARING:
		var duel_ended := await _enemy_attack()
		if duel_ended:
			return
		enemy_state = STATE_GUARDING
		status_label.text = "Враг поднял защиту. Разбейте её атаками."
	elif enemy_state == STATE_GUARDING:
		enemy_state = STATE_OPEN
		status_label.text = "Враг открыт. Сейчас атака наносит урон здоровью."
	else:
		enemy_state = STATE_PREPARING
		status_label.text = "Враг готовит следующий удар."

	_update_ui()
	state_timer.start()

func _on_attack_pressed() -> void:
	if duel_finished or input_locked:
		return

	input_locked = true
	player_guarding = false
	state_timer.stop()
	_update_ui()

	await _lunge(player_marker, player_start_position, Vector3(0.9, 0.0, 0.0))

	match enemy_state:
		STATE_OPEN:
			enemy_hp -= DAMAGE
			status_label.text = "Попадание: здоровье врага -%d." % DAMAGE
		STATE_GUARDING:
			if enemy_defense > 0:
				enemy_defense = max(0, enemy_defense - DAMAGE)
				if enemy_defense == 0:
					status_label.text = "Защита врага сломана."
				else:
					status_label.text = "Удар по защите врага: DEF -%d." % DAMAGE
			else:
				enemy_hp -= DAMAGE
				status_label.text = "Защиты нет: здоровье врага -%d." % DAMAGE
		STATE_PREPARING:
			_apply_damage_to_player("Враг парировал поспешную атаку.")

	if _check_duel_end():
		return

	input_locked = false
	_update_ui()
	state_timer.start()

func _on_guard_pressed() -> void:
	if duel_finished or input_locked:
		return
	if player_defense <= 0:
		status_label.text = "Защита сломана. Теперь можно только атаковать."
		_update_ui()
		return

	player_guarding = true
	status_label.text = "Защита активна до следующего удара врага."
	_animate_guard(player_marker, player_start_position, -10.0)
	_update_ui()

func _enemy_attack() -> bool:
	input_locked = true
	state_timer.stop()
	_update_ui()

	await _lunge(enemy_marker, enemy_start_position, Vector3(-0.9, 0.0, 0.0))
	_apply_damage_to_player("Враг атаковал.")

	if _check_duel_end():
		return true

	input_locked = false
	_update_ui()
	return false

func _apply_damage_to_player(prefix: String) -> void:
	if player_guarding and player_defense > 0:
		player_defense = max(0, player_defense - DAMAGE)
		player_guarding = false
		if player_defense == 0:
			status_label.text = prefix + " Защита приняла удар и сломалась."
		else:
			status_label.text = prefix + " Защита приняла удар: DEF -%d." % DAMAGE
	else:
		player_hp -= DAMAGE
		player_guarding = false
		status_label.text = prefix + " Здоровье игрока -%d." % DAMAGE

func _check_duel_end() -> bool:
	if enemy_hp <= 0:
		duel_finished = true
		state_timer.stop()
		status_label.text = "Победа. Враг побеждён."
		_update_ui()
		call_deferred("_finish_duel", true)
		return true
	if player_hp <= 0:
		duel_finished = true
		state_timer.stop()
		status_label.text = "Поражение. Возвращение на уровень."
		_update_ui()
		call_deferred("_finish_duel", false)
		return true
	return false

func _finish_duel(player_won: bool) -> void:
	if player_won:
		GameManager.finish_duel_win()
	else:
		GameManager.finish_duel_lose()

func _lunge(marker: MeshInstance3D, origin: Vector3, offset: Vector3) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(marker, "position", origin + offset, 0.12)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(marker, "position", origin, 0.16)
	await tween.finished

func _animate_guard(marker: MeshInstance3D, origin: Vector3, tilt_degrees: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(marker, "rotation_degrees:z", tilt_degrees, 0.12)
	tween.parallel().tween_property(marker, "position:y", origin.y + 0.12, 0.12)
	tween.tween_property(marker, "rotation_degrees:z", 0.0, 0.18)
	tween.parallel().tween_property(marker, "position:y", origin.y, 0.18)

func _state_text() -> String:
	match enemy_state:
		STATE_PREPARING:
			return "готовит атаку"
		STATE_GUARDING:
			return "защищается"
		STATE_OPEN:
			return "открыт"
	return "неизвестно"

func _update_ui() -> void:
	player_hp_label.text = "Игрок HP: %d/%d" % [max(0, player_hp), MAX_HP]
	player_defense_label.text = "Игрок DEF: %d/%d" % [player_defense, MAX_DEFENSE]
	enemy_hp_label.text = "Враг HP: %d/%d" % [max(0, enemy_hp), MAX_HP]
	enemy_defense_label.text = "Враг DEF: %d/%d" % [enemy_defense, MAX_DEFENSE]
	enemy_state_label.text = "Состояние врага: " + _state_text()
	guard_button.text = "ЗАЩИТА АКТИВНА" if player_guarding else "ЗАЩИТА"
	attack_button.disabled = input_locked or duel_finished
	guard_button.disabled = input_locked or duel_finished or player_defense <= 0
