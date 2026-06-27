extends Node

var saved_player_2d_position = Vector2.ZERO
var active_enemy_id = ""
var active_enemy_level = 1
var defeated_enemy_ids = []
var returning_from_duel = false

const LEVEL_2D_SCENE = "res://scenes/Level2D.tscn"
const DUEL_ARENA_3D_SCENE = "res://scenes/DuelArena3D.tscn"

func start_duel(enemy_id, player_position, enemy_level):
	if defeated_enemy_ids.has(enemy_id):
		return

	saved_player_2d_position = player_position
	active_enemy_id = enemy_id
	active_enemy_level = enemy_level
	returning_from_duel = false
	get_tree().change_scene_to_file(DUEL_ARENA_3D_SCENE)

func finish_duel_win():
	if active_enemy_id != "" and not defeated_enemy_ids.has(active_enemy_id):
		defeated_enemy_ids.append(active_enemy_id)

	returning_from_duel = true
	get_tree().change_scene_to_file(LEVEL_2D_SCENE)

func finish_duel_lose():
	returning_from_duel = true
	get_tree().change_scene_to_file(LEVEL_2D_SCENE)

func reset_game():
	saved_player_2d_position = Vector2.ZERO
	active_enemy_id = ""
	active_enemy_level = 1
	defeated_enemy_ids.clear()
	returning_from_duel = false
	get_tree().change_scene_to_file(LEVEL_2D_SCENE)
