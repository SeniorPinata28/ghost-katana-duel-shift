extends Node

signal run_state_changed
signal level_completed

const LEVEL_2D_SCENE := "res://scenes/levels/Level2D.tscn"
const DUEL_3D_SCENE := "res://scenes/duel/DuelArena3D.tscn"

var current_enemy_id := ""
var current_enemy_level := 1
var current_duel_kind := "elite"
var current_duel_context: Dictionary = {}

var saved_player_2d_position := Vector2(120, 400)
var checkpoint_position := Vector2(120, 400)
var returning_from_duel := false
var scene_change_pending := false

var defeated_enemy_ids: Dictionary = {}
var defeated_ordinary_ids: Dictionary = {}
var destroyed_object_ids: Dictionary = {}
var story_flags: Dictionary = {}

var artifact_collected := false
var selected_technique := "blade"
var seal_charges := 0
var special_energy := 0.0
var focus_active := false
var alarm_level := 0
var duel_debris := false
var boss_defeated := false
var level_1_complete := false

func _ready() -> void:
	SaveManager.load_game()
	level_1_complete = SaveManager.level_1_complete

func start_duel(enemy_id: String, duel_kind: String, player_position: Vector2, enemy_level: int, context: Dictionary) -> void:
	if scene_change_pending:
		return
	current_enemy_id = enemy_id
	current_duel_kind = duel_kind
	current_enemy_level = enemy_level
	current_duel_context = context.duplicate(true)
	saved_player_2d_position = player_position
	returning_from_duel = true
	focus_active = false
	SfxManager.play_cue("duel")
	_change_scene(DUEL_3D_SCENE)

func finish_duel_win() -> void:
	if current_enemy_id != "":
		defeated_enemy_ids[current_enemy_id] = true
	if current_duel_kind == "boss":
		boss_defeated = true
	checkpoint_position = saved_player_2d_position + Vector2(80, 0)
	returning_from_duel = true
	focus_active = false
	run_state_changed.emit()
	_change_scene(LEVEL_2D_SCENE)

func finish_duel_lose() -> void:
	returning_from_duel = true
	saved_player_2d_position = checkpoint_position
	focus_active = false
	_change_scene(LEVEL_2D_SCENE)

func restart_from_checkpoint() -> void:
	returning_from_duel = true
	saved_player_2d_position = checkpoint_position
	focus_active = false
	_change_scene(LEVEL_2D_SCENE)

func reset_run() -> void:
	current_enemy_id = ""
	current_enemy_level = 1
	current_duel_kind = "elite"
	current_duel_context.clear()
	saved_player_2d_position = Vector2(120, 400)
	checkpoint_position = Vector2(120, 400)
	returning_from_duel = false
	defeated_enemy_ids.clear()
	defeated_ordinary_ids.clear()
	destroyed_object_ids.clear()
	story_flags.clear()
	artifact_collected = false
	selected_technique = "blade"
	seal_charges = 0
	special_energy = 0.0
	focus_active = false
	alarm_level = 0
	duel_debris = false
	boss_defeated = false
	run_state_changed.emit()
	_change_scene(LEVEL_2D_SCENE)

func mark_ordinary_defeated(enemy_id: String) -> void:
	if enemy_id != "":
		defeated_ordinary_ids[enemy_id] = true
	run_state_changed.emit()

func mark_destroyed(object_id: String, creates_duel_debris: bool = false) -> void:
	if object_id != "":
		destroyed_object_ids[object_id] = true
	if creates_duel_debris:
		duel_debris = true
	run_state_changed.emit()

func collect_artifact(technique: String) -> void:
	artifact_collected = true
	selected_technique = technique
	seal_charges = maxi(seal_charges, 1)
	special_energy = 100.0
	story_flags["artifact_collected"] = true
	SfxManager.play_cue("artifact")
	run_state_changed.emit()

func add_special_energy(amount: float) -> void:
	special_energy = clampf(special_energy + amount, 0.0, 100.0)
	run_state_changed.emit()

func spend_special_energy(amount: float) -> bool:
	if special_energy + 0.001 < amount:
		return false
	special_energy = maxf(0.0, special_energy - amount)
	run_state_changed.emit()
	return true

func consume_seal() -> bool:
	if seal_charges <= 0:
		return false
	seal_charges -= 1
	SfxManager.play_cue("seal")
	run_state_changed.emit()
	return true

func set_checkpoint(position: Vector2) -> void:
	checkpoint_position = position
	saved_player_2d_position = position

func set_story_seen(flag_name: String) -> void:
	story_flags[flag_name] = true

func is_story_seen(flag_name: String) -> bool:
	return story_flags.has(flag_name)

func complete_level_1() -> void:
	level_1_complete = true
	SaveManager.mark_level_1_complete()
	level_completed.emit()

func world_time_factor() -> float:
	return 0.35 if focus_active else 1.0

func _change_scene(path: String) -> void:
	if scene_change_pending:
		return
	scene_change_pending = true
	_change_scene_deferred.call_deferred(path)

func _change_scene_deferred(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	scene_change_pending = false
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
