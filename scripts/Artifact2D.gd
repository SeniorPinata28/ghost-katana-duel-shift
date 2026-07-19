extends Area2D

signal artifact_activated(artifact: Area2D)

@export var artifact_id := "zero_seal_fragment"
var activated := false

func _ready() -> void:
	if GameManager.artifact_collected:
		queue_free()
		return
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotation += delta * 0.8
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		visual.scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.08)

func _on_body_entered(body: Node2D) -> void:
	if activated or not body.is_in_group("player_2d"):
		return
	activated = true
	set_deferred("monitoring", false)
	artifact_activated.emit(self)
