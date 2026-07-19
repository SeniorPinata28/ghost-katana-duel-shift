extends Area2D

@export var enemy_id := "elite_01"
@export_enum("elite", "boss") var duel_kind := "elite"
@export var enemy_level := 1
@export var required_artifact := true
@export var required_enemy_id := ""

var duel_started := false

func _ready() -> void:
	add_to_group("duel_triggers_2d")
	body_entered.connect(_on_body_entered)
	if GameManager.defeated_enemy_ids.has(enemy_id):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if duel_started or GameManager.defeated_enemy_ids.has(enemy_id):
		return
	if not body.is_in_group("player_2d"):
		return
	if required_artifact and not GameManager.artifact_collected:
		if body.has_method("show_status"):
			body.show_status("Сначала найдите Осколок Нулевой Печати")
		return
	if required_enemy_id != "" and not GameManager.defeated_enemy_ids.has(required_enemy_id):
		if body.has_method("show_status"):
			body.show_status("Путь к этой дуэли ещё закрыт")
		return
	duel_started = true
	set_deferred("monitoring", false)
	var context := {
		"high_ground": body.global_position.y < global_position.y - 55.0,
		"stealth": GameManager.alarm_level == 0,
		"debris": GameManager.duel_debris,
		"alarm": GameManager.alarm_level > 0,
		"technique": GameManager.selected_technique,
		"seal": GameManager.seal_charges
	}
	GameManager.start_duel(enemy_id, duel_kind, body.global_position, enemy_level, context)
