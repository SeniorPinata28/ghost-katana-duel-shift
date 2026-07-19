extends Area2D

var rescued := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if rescued or not body.is_in_group("player_2d"):
		return
	rescued = true
	set_deferred("monitoring", false)
	if body.has_method("unlock_berserk"):
		body.unlock_berserk()
	if body.has_method("add_rage"):
		body.add_rage(100)
	queue_free()
