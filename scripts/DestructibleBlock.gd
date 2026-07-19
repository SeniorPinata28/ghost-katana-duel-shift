extends StaticBody2D

@export var max_health := 3
@export var rage_reward := 12

var health := 3

func _ready() -> void:
	health = max_health
	add_to_group("destructible_2d")
	_update_visual()

func take_damage(amount: int, source: Node = null) -> void:
	health -= amount
	_update_visual()
	if health <= 0:
		if is_instance_valid(source) and source.has_method("add_rage"):
			source.add_rage(rage_reward)
		call_deferred("queue_free")

func _update_visual() -> void:
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual == null:
		return
	var ratio := clamp(float(health) / float(max_health), 0.0, 1.0)
	visual.color = Color(0.38 + ratio * 0.30, 0.20 + ratio * 0.20, 0.10, 1.0)
