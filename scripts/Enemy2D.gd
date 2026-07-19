extends Area2D

@export var enemy_id := "enemy_01"
@export var enemy_level := 1

var duel_started := false

func _ready() -> void:
	add_to_group("enemies_2d")
	body_entered.connect(_on_body_entered)

	if GameManager.defeated_enemy_ids.has(enemy_id):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if duel_started:
		return
	if GameManager.defeated_enemy_ids.has(enemy_id):
		return
	if body.name != "Player2D":
		return

	duel_started = true
	set_deferred("monitoring", false)
	GameManager.start_duel(enemy_id, body.global_position, enemy_level)
