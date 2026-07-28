extends StaticBody2D

@export_enum("weak", "reinforced", "structural") var strength := "weak"
@export var object_id := "block_01"
@export var max_health := 2
@export var energy_reward := 12.0
@export var creates_duel_debris := false

var health := 2

func _ready() -> void:
	if GameManager.destroyed_object_ids.has(object_id):
		queue_free()
		return
	health = max_health
	add_to_group("destructible_2d")
	_update_visual()

func take_damage(amount: int, source: Node = null, damage_type: String = "slash") -> void:
	if strength == "structural":
		_flash_denied()
		return
	if strength == "reinforced" and damage_type != "heavy" and damage_type != "explosive":
		_flash_denied()
		return
	health -= amount
	_update_visual()
	if health <= 0:
		GameManager.mark_destroyed(object_id, creates_duel_debris)
		if is_instance_valid(source) and source.has_method("add_energy"):
			source.add_energy(energy_reward)
		SfxManager.play_cue("break")
		queue_free()

func _flash_denied() -> void:
	modulate = Color(0.65, 0.75, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.14)

func _update_visual() -> void:
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual == null:
		return
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	match strength:
		"reinforced":
			visual.color = Color(0.32 + ratio * 0.18, 0.36 + ratio * 0.18, 0.42 + ratio * 0.18, 1.0)
		"structural":
			visual.color = Color(0.20, 0.22, 0.26, 1.0)
		_:
			visual.color = Color(0.38 + ratio * 0.28, 0.19 + ratio * 0.18, 0.08, 1.0)
