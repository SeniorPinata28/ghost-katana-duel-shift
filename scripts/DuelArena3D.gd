extends Node3D

const PLAYER_MAX_POSTURE := 3
const PARRY_WINDOW := 0.22
const DODGE_WINDOW := 0.38
const DODGE_COOLDOWN := 0.85

var player_posture := PLAYER_MAX_POSTURE
var enemy_posture := 3
var enemy_max_posture := 3
var boss_phase := 1
var enemy_open := false
var player_guarding := false
var guard_pressed_at := -10.0
var dodge_until := -10.0
var dodge_cooldown_until := -10.0
var input_locked := false
var duel_finished := false
var attack_index := 0

var player_origin := Vector3.ZERO
var enemy_origin := Vector3.ZERO

@onready var player_root: Node3D = $PlayerRoot
@onready var enemy_root: Node3D = $EnemyRoot
@onready var debris: Node3D = $ArenaDebris
@onready var title_label: Label = $UI/TopPanel/TitleLabel
@onready var player_state_label: Label = $UI/TopPanel/PlayerStateLabel
@onready var enemy_state_label: Label = $UI/TopPanel/EnemyStateLabel
@onready var telegraph_label: Label = $UI/TopPanel/TelegraphLabel
@onready var status_label: Label = $UI/TopPanel/StatusLabel
@onready var quick_button: Button = $UI/QuickButton
@onready var heavy_button: Button = $UI/HeavyButton
@onready var guard_button: Button = $UI/GuardButton
@onready var dodge_button: Button = $UI/DodgeButton

func _ready() -> void:
	GameManager.scene_change_pending = false
	player_origin = player_root.position
	enemy_origin = enemy_root.position
	quick_button.pressed.connect(_on_quick_pressed)
	heavy_button.pressed.connect(_on_heavy_pressed)
	guard_button.pressed.connect(_on_guard_pressed)
	dodge_button.pressed.connect(_on_dodge_pressed)
	debris.visible = bool(GameManager.current_duel_context.get("debris", false))
	if GameManager.current_duel_kind == "boss":
		enemy_max_posture = 4
		title_label.text = "БОСС — КЭНСЭЙ ПЕПЕЛЬНОЙ МАСКИ"
	else:
		enemy_max_posture = 3
		title_label.text = "ЭЛИТНАЯ ДУЭЛЬ — СТРАЖ РАЗЛОМА"
	enemy_posture = enemy_max_posture
	_apply_approach_context()
	_update_ui()
	_enemy_loop.call_deferred()

func _apply_approach_context() -> void:
	var context := GameManager.current_duel_context
	var notes: Array[String] = []
	if bool(context.get("high_ground", false)):
		enemy_posture = maxi(1, enemy_posture - 1)
		notes.append("атака сверху: стойка врага ослаблена")
	if bool(context.get("stealth", false)):
		enemy_open = true
		notes.append("скрытное приближение: доступен первый чистый удар")
	if bool(context.get("debris", false)):
		notes.append("разрушенная опора изменила арену")
	if bool(context.get("alarm", false)):
		notes.append("тревога: враг атакует быстрее")
	if notes.is_empty():
		status_label.text = "Разбейте стойку врага, затем нанесите чистый удар."
	else:
		status_label.text = "; ".join(PackedStringArray(notes))

func _enemy_loop() -> void:
	await get_tree().create_timer(0.75).timeout
	while not duel_finished:
		if enemy_open:
			telegraph_label.text = "ВРАГ ОТКРЫТ"
			await get_tree().create_timer(1.65).timeout
			if duel_finished:
				return
			if enemy_open:
				enemy_open = false
				enemy_posture = enemy_max_posture
				status_label.text = "Враг восстановил стойку."
				_update_ui()
			continue
		await _enemy_attack_sequence()
		if not duel_finished:
			await get_tree().create_timer(0.48).timeout

func _enemy_attack_sequence() -> void:
	attack_index += 1
	var attack_name := "ВЕРХНИЙ УДАР" if attack_index % 2 == 1 else "БОКОВОЙ РАЗРЕЗ"
	var telegraph_time := 0.90
	if GameManager.current_duel_kind == "boss":
		telegraph_time -= 0.10 * float(boss_phase)
	if bool(GameManager.current_duel_context.get("alarm", false)):
		telegraph_time -= 0.16
	if bool(GameManager.current_duel_context.get("debris", false)):
		telegraph_time += 0.12
	telegraph_time = maxf(0.42, telegraph_time)
	telegraph_label.text = attack_name + " — %.2f с" % telegraph_time
	status_label.text = "Защита в последний момент даст идеальное парирование."
	var windup := create_tween()
	windup.tween_property(enemy_root, "rotation_degrees:z", -18.0 if attack_index % 2 == 1 else 18.0, telegraph_time * 0.75)
	await get_tree().create_timer(telegraph_time).timeout
	if duel_finished or enemy_open:
		enemy_root.rotation_degrees.z = 0.0
		return
	input_locked = true
	_update_ui()
	await _lunge(enemy_root, enemy_origin, Vector3(-1.35, 0.0, 0.0), 0.10, 0.15)
	enemy_root.rotation_degrees.z = 0.0
	_resolve_enemy_impact()
	input_locked = false
	_update_ui()

func _resolve_enemy_impact() -> void:
	var now := _now()
	if now <= dodge_until:
		status_label.text = "Уклонение: удар прошёл мимо. Стойка врага ослаблена."
		_damage_enemy_posture(1)
		player_guarding = false
		return
	if player_guarding and player_posture > 0:
		var timing := now - guard_pressed_at
		if timing <= PARRY_WINDOW:
			status_label.text = "ИДЕАЛЬНОЕ ПАРИРОВАНИЕ: стойка врага разрушена."
			_damage_enemy_posture(2)
			SfxManager.play_cue("parry")
		else:
			player_posture = maxi(0, player_posture - 1)
			status_label.text = "Блок принят. Потерян сегмент стойки."
			SfxManager.play_cue("hit")
		player_guarding = false
		return
	_apply_lethal_to_player()

func _on_quick_pressed() -> void:
	if duel_finished or input_locked:
		return
	input_locked = true
	player_guarding = false
	await _lunge(player_root, player_origin, Vector3(1.15, 0.0, 0.0), 0.09, 0.13)
	if enemy_open:
		_clean_hit_enemy()
	else:
		var posture_damage := 2 if GameManager.selected_technique == "blade" and GameManager.current_duel_kind == "elite" else 1
		_damage_enemy_posture(posture_damage)
		status_label.text = "Быстрый удар: стойка врага -%d." % posture_damage
	SfxManager.play_cue("attack")
	input_locked = false
	_update_ui()

func _on_heavy_pressed() -> void:
	if duel_finished or input_locked:
		return
	input_locked = true
	player_guarding = false
	status_label.text = "Сильный удар готовится..."
	await get_tree().create_timer(0.30).timeout
	if duel_finished:
		return
	await _lunge(player_root, player_origin, Vector3(1.45, 0.0, 0.0), 0.12, 0.18)
	if enemy_open:
		_clean_hit_enemy()
	else:
		var posture_damage := 3 if GameManager.selected_technique == "breaker" else 2
		_damage_enemy_posture(posture_damage)
		status_label.text = "Сильный удар: стойка врага -%d." % posture_damage
	SfxManager.play_cue("heavy")
	input_locked = false
	_update_ui()

func _on_guard_pressed() -> void:
	if duel_finished or input_locked or player_posture <= 0:
		return
	player_guarding = true
	guard_pressed_at = _now()
	status_label.text = "Защита поднята. Для парирования нажимайте ближе к моменту удара."
	var tween := create_tween()
	tween.tween_property(player_root, "rotation_degrees:z", -12.0, 0.10)
	_update_ui()

func _on_dodge_pressed() -> void:
	if duel_finished or input_locked:
		return
	var now := _now()
	if now < dodge_cooldown_until:
		status_label.text = "Уклонение восстанавливается."
		return
	dodge_until = now + DODGE_WINDOW
	dodge_cooldown_until = now + DODGE_COOLDOWN
	player_guarding = false
	var tween := create_tween()
	tween.tween_property(player_root, "position:z", player_origin.z + 1.4, 0.10)
	tween.tween_property(player_root, "position:z", player_origin.z, 0.22)
	status_label.text = "Уклонение активно."
	_update_ui()

func _damage_enemy_posture(amount: int) -> void:
	if enemy_open or duel_finished:
		return
	enemy_posture = maxi(0, enemy_posture - amount)
	if enemy_posture <= 0:
		enemy_open = true
		telegraph_label.text = "СТОЙКА СЛОМАНА"
		status_label.text = "Враг открыт. Следующий чистый удар решит фазу."

func _clean_hit_enemy() -> void:
	if duel_finished:
		return
	if GameManager.current_duel_kind == "boss" and boss_phase == 1:
		boss_phase = 2
		enemy_open = false
		enemy_max_posture = 5
		enemy_posture = enemy_max_posture
		enemy_root.scale = Vector3(1.12, 1.12, 1.12)
		status_label.text = "ФАЗА 2: маска расколота. Кэнсэй ускоряется."
		telegraph_label.text = "ВТОРАЯ ФАЗА"
		SfxManager.play_cue("break")
		return
	duel_finished = true
	status_label.text = "Чистый удар. Победа в дуэли."
	telegraph_label.text = "ПОБЕДА"
	SfxManager.play_cue("win")
	_update_ui()
	_finish_after_delay.call_deferred(true)

func _apply_lethal_to_player() -> void:
	if GameManager.consume_seal():
		player_posture = PLAYER_MAX_POSTURE
		status_label.text = "Печать поглотила смертельный удар. Стойка восстановлена."
		return
	duel_finished = true
	status_label.text = "Чистое попадание. Дуэль проиграна."
	telegraph_label.text = "ПОРАЖЕНИЕ"
	SfxManager.play_cue("hit")
	_update_ui()
	_finish_after_delay.call_deferred(false)

func _finish_after_delay(player_won: bool) -> void:
	await get_tree().create_timer(0.85).timeout
	if player_won:
		GameManager.finish_duel_win()
	else:
		GameManager.finish_duel_lose()

func _lunge(node: Node3D, origin: Vector3, offset: Vector3, out_time: float, back_time: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", origin + offset, out_time)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "position", origin, back_time)
	await tween.finished

func _update_ui() -> void:
	player_state_label.text = "ИГРОК  СТОЙКА %d/%d  ПЕЧАТЬ %d" % [player_posture, PLAYER_MAX_POSTURE, GameManager.seal_charges]
	var phase_text := "  ФАЗА %d/2" % boss_phase if GameManager.current_duel_kind == "boss" else ""
	enemy_state_label.text = "ВРАГ  СТОЙКА %d/%d%s" % [enemy_posture, enemy_max_posture, phase_text]
	guard_button.text = "ЗАЩИТА АКТИВНА" if player_guarding else "ЗАЩИТА"
	quick_button.disabled = input_locked or duel_finished
	heavy_button.disabled = input_locked or duel_finished
	guard_button.disabled = input_locked or duel_finished or player_posture <= 0
	dodge_button.disabled = input_locked or duel_finished

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
