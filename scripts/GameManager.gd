extends Node

const LEVEL_2D_SCENE := "res://scenes/levels/Level2D.tscn"
const DUEL_3D_SCENE := "res://scenes/duel/DuelArena3D.tscn"

var current_enemy_id := ""
var current_enemy_level := 1
var saved_player_2d_position := Vector2.ZERO
var returning_from_duel := false
var defeated_enemy_ids: Array[String] = []
var scene_change_pending := false

func start_duel(enemy_id: String, player_position: Vector2, enemy_level: int = 1) -> void:
	current_enemy_id = enemy_id
	current_enemy_level = enemy_level
	saved_player_2d_position = player_position
	returning_from_duel = true
	_change_scene(DUEL_3D_SCENE)

func finish_duel_win() -> void:
	if current_enemy_id != "" and not defeated_enemy_ids.has(current_enemy_id):
		defeated_enemy_ids.append(current_enemy_id)
	_change_scene(LEVEL_2D_SCENE)

func finish_duel_lose() -> void:
	returning_from_duel = true
	_change_scene(LEVEL_2D_SCENE)

func reset_run() -> void:
	current_enemy_id = ""
	current_enemy_level = 1
	saved_player_2d_position = Vector2.ZERO
	returning_from_duel = false
	defeated_enemy_ids.clear()
	_change_scene(LEVEL_2D_SCENE)

func _change_scene(path: String) -> void:
	if scene_change_pending:
		return
	scene_change_pending = true
	_change_scene_deferred.call_deferred(path)

func _change_scene_deferred(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		scene_change_pending = false
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
