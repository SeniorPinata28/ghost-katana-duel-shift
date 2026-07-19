extends StaticBody2D

@export var required_enemy_id := "elite_01"

func _ready() -> void:
	if GameManager.defeated_enemy_ids.has(required_enemy_id):
		queue_free()

func _process(_delta: float) -> void:
	if GameManager.defeated_enemy_ids.has(required_enemy_id):
		SfxManager.play_cue("artifact")
		queue_free()
