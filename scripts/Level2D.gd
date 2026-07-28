extends Node2D

@onready var player: CharacterBody2D = $Player2D
@onready var artifact: Area2D = $World/Artifact
@onready var checkpoint_area: Area2D = $World/CheckpointAfterElite
@onready var exit_area: Area2D = $World/Exit

@onready var left_button: Button = $MobileUI/LeftButton
@onready var right_button: Button = $MobileUI/RightButton
@onready var jump_button: Button = $MobileUI/JumpButton
@onready var dash_focus_button: Button = $MobileUI/DashFocusButton
@onready var attack_button: Button = $MobileUI/AttackButton
@onready var technique_button: Button = $MobileUI/TechniqueButton
@onready var restart_button: Button = $MobileUI/RestartButton

@onready var objective_label: Label = $MobileUI/TopPanel/ObjectiveLabel
@onready var stats_label: Label = $MobileUI/TopPanel/StatsLabel
@onready var status_label: Label = $MobileUI/TopPanel/StatusLabel

@onready var artifact_panel: Panel = $MobileUI/ArtifactPanel
@onready var blade_button: Button = $MobileUI/ArtifactPanel/BladeButton
@onready var breaker_button: Button = $MobileUI/ArtifactPanel/BreakerButton
@onready var artifact_text: Label = $MobileUI/ArtifactPanel/ArtifactText

@onready var story_panel: Panel = $MobileUI/StoryPanel
@onready var story_title: Label = $MobileUI/StoryPanel/StoryTitle
@onready var story_text: Label = $MobileUI/StoryPanel/StoryText
@onready var story_continue: Button = $MobileUI/StoryPanel/ContinueButton

@onready var end_panel: Panel = $MobileUI/EndPanel
@onready var end_text: Label = $MobileUI/EndPanel/EndText

var attack_press_time := 0.0
var dash_press_time := 0.0
var dash_held := false
var focus_triggered := false
var current_artifact: Area2D = null
var queued_story_flag := ""
var returned_from_duel_this_load := false

func _ready() -> void:
	GameManager.scene_change_pending = false
	_place_player()
	_connect_controls()
	if is_instance_valid(artifact) and not artifact.is_queued_for_deletion():
		artifact.artifact_activated.connect(_on_artifact_activated)
	checkpoint_area.body_entered.connect(_on_checkpoint_entered)
	exit_area.body_entered.connect(_on_exit_entered)
	player.status_changed.connect(_on_player_status_changed)
	player.player_died.connect(func() -> void: status_label.text = "Смертельный удар")
	GameManager.run_state_changed.connect(_update_objective)
	_update_objective()
	if not GameManager.is_story_seen("level_intro"):
		_show_story(
			"УРОВЕНЬ 1 — ХРАМ РАЗЛОМА",
			"Маска Пепла открыла нестабильный разлом под старым храмом. Пройдите разрушенный нижний ярус, найдите Осколок Нулевой Печати и доберитесь до хранителя ворот.",
			"level_intro"
		)
	elif returned_from_duel_this_load and GameManager.defeated_enemy_ids.has("elite_01") and not GameManager.is_story_seen("elite_defeated"):
		_show_story(
			"ВОРОТА РАЗЛОМА ОТКРЫТЫ",
			"Страж повержен. Разрушения в храме сохранились, а проход к верхнему двору теперь открыт. Впереди — Кэнсэй Пепельной Маски.",
			"elite_defeated"
		)

func _process(_delta: float) -> void:
	stats_label.text = "ПЕЧАТЬ %d   ТЕХНИКА %s   ЭНЕРГИЯ %d%%" % [GameManager.seal_charges, player.technique_name(), int(GameManager.special_energy)]
	dash_focus_button.text = "ФОКУС" if GameManager.focus_active else player.get_dash_text()
	technique_button.text = "ТЕХНИКА\n%s" % player.technique_name()
	if not story_panel.visible and GameManager.defeated_enemy_ids.has("elite_01") and player.global_position.x > 2070.0 and not GameManager.is_story_seen("boss_intro"):
		_show_story(
			"КЭНСЭЙ ПЕПЕЛЬНОЙ МАСКИ",
			"Хранитель верхнего двора использует разлом как вторую стойку. Первый чистый удар только расколет маску. Второй завершит дуэль.",
			"boss_intro"
		)
	if dash_held and not focus_triggered and Time.get_ticks_msec() / 1000.0 - dash_press_time >= 0.45:
		focus_triggered = true
		player.set_focus_requested(true)
		status_label.text = "Фокус: мир замедлен, энергия расходуется"

func _connect_controls() -> void:
	left_button.button_down.connect(func() -> void: Input.action_press("move_left"))
	left_button.button_up.connect(func() -> void: Input.action_release("move_left"))
	right_button.button_down.connect(func() -> void: Input.action_press("move_right"))
	right_button.button_up.connect(func() -> void: Input.action_release("move_right"))
	jump_button.button_down.connect(func() -> void: Input.action_press("jump"))
	jump_button.button_up.connect(func() -> void: Input.action_release("jump"))
	attack_button.button_down.connect(_on_attack_down)
	attack_button.button_up.connect(_on_attack_up)
	dash_focus_button.button_down.connect(_on_dash_down)
	dash_focus_button.button_up.connect(_on_dash_up)
	technique_button.pressed.connect(player.use_technique)
	restart_button.pressed.connect(GameManager.reset_run)
	blade_button.pressed.connect(func() -> void: _choose_technique("blade"))
	breaker_button.pressed.connect(func() -> void: _choose_technique("breaker"))
	story_continue.pressed.connect(_close_story)

func _exit_tree() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	player.set_focus_requested(false)

func _place_player() -> void:
	returned_from_duel_this_load = GameManager.returning_from_duel
	if returned_from_duel_this_load:
		player.global_position = GameManager.saved_player_2d_position
		GameManager.returning_from_duel = false
	else:
		player.global_position = GameManager.checkpoint_position

func _on_attack_down() -> void:
	attack_press_time = Time.get_ticks_msec() / 1000.0

func _on_attack_up() -> void:
	var held := Time.get_ticks_msec() / 1000.0 - attack_press_time
	if held >= 0.42:
		player.strong_attack()
	else:
		player.quick_attack()

func _on_dash_down() -> void:
	dash_press_time = Time.get_ticks_msec() / 1000.0
	dash_held = true
	focus_triggered = false

func _on_dash_up() -> void:
	dash_held = false
	if focus_triggered:
		player.set_focus_requested(false)
		status_label.text = "Фокус завершён"
	else:
		player.request_dash()

func _on_artifact_activated(source_artifact: Area2D) -> void:
	current_artifact = source_artifact
	player.controls_locked = true
	artifact_panel.visible = true
	artifact_text.text = "Осколок Нулевой Печати восстановит одну защитную печать, заполнит энергию техники и позволит выбрать стиль для этого прохождения."
	SfxManager.play_cue("artifact")

func _choose_technique(technique: String) -> void:
	GameManager.collect_artifact(technique)
	artifact_panel.visible = false
	if is_instance_valid(current_artifact):
		current_artifact.queue_free()
	current_artifact = null
	player.controls_locked = false
	status_label.text = "Получена техника: %s. Печать поглотит один смертельный удар." % player.technique_name()
	_show_story(
		"ОСКОЛОК НУЛЕВОЙ ПЕЧАТИ",
		"Реликвия хранит отпечатки прежних владельцев катаны. Она не меняет героя — только перестраивает способ, которым клинок взаимодействует с разломом.",
		"artifact_story"
	)
	_update_objective()

func _on_checkpoint_entered(body: Node2D) -> void:
	if body != player or not GameManager.defeated_enemy_ids.has("elite_01"):
		return
	GameManager.set_checkpoint(Vector2(1680, 400))
	status_label.text = "Контрольная точка: верхний двор"

func _on_exit_entered(body: Node2D) -> void:
	if body != player:
		return
	if not GameManager.boss_defeated:
		status_label.text = "Выход запечатан силой босса"
		return
	if GameManager.level_1_complete:
		return
	GameManager.complete_level_1()
	player.controls_locked = true
	end_panel.visible = true
	end_text.text = "УРОВЕНЬ 1 ЗАВЕРШЁН\n\nРазлом под храмом стабилизирован, но Маска Пепла была лишь проводником. В глубине открывается след человека, который знал прежнего владельца катаны."
	SfxManager.play_cue("win")

func _update_objective() -> void:
	if not GameManager.artifact_collected:
		objective_label.text = "ЦЕЛЬ: найдите Осколок Нулевой Печати в верхней комнате"
	elif not GameManager.defeated_enemy_ids.has("elite_01"):
		objective_label.text = "ЦЕЛЬ: доберитесь до элитного Стража Разлома"
	elif not GameManager.boss_defeated:
		objective_label.text = "ЦЕЛЬ: пройдите верхний двор и победите Кэнсэя Маски"
	else:
		objective_label.text = "ЦЕЛЬ: покиньте храм через правые ворота"

func _on_player_status_changed(message: String) -> void:
	status_label.text = message

func _show_story(title: String, text: String, flag_name: String) -> void:
	if GameManager.is_story_seen(flag_name):
		return
	queued_story_flag = flag_name
	story_title.text = title
	story_text.text = text
	story_panel.visible = true
	player.controls_locked = true

func _close_story() -> void:
	story_panel.visible = false
	player.controls_locked = false
	if queued_story_flag != "":
		GameManager.set_story_seen(queued_story_flag)
	queued_story_flag = ""
