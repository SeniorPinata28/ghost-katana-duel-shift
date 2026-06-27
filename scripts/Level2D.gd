extends Node2D

@onready var player: CharacterBody2D = $Player2D
@onready var exit_area: Area2D = $Exit

const START_POSITION := Vector2(120, 360)

func _ready() -> void:
	_remove_defeated_enemies()
	_place_player()
	exit_area.body_entered.connect(_on_exit_body_entered)

func _place_player() -> void:
	if GameManager.returning_from_duel:
		player.global_position = GameManager.saved_player_2d_position
		GameManager.returning_from_duel = false
	else:
		player.global_position = START_POSITION

func _remove_defeated_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies_2d"):
		if enemy.enemy_id in GameManager.defeated_enemy_ids:
			enemy.queue_free()

func _on_exit_body_entered(body: Node) -> void:
	if body == player and GameManager.defeated_enemy_ids.has("enemy_01"):
		print("Level complete")
