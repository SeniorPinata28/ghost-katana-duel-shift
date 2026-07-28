extends Area2D

var direction := 1.0
var speed := 360.0
var life_time := 3.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	shape_node.shape = shape
	add_child(shape_node)
	var visual := Polygon2D.new()
	visual.color = Color(1.0, 0.2, 0.18, 1.0)
	visual.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(0, -7), Vector2(7, 0), Vector2(0, 7)])
	add_child(visual)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var factor := GameManager.world_time_factor()
	position.x += direction * speed * delta * factor
	life_time -= delta * factor
	if life_time <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_2d") and body.has_method("take_lethal_hit"):
		body.take_lethal_hit(direction)
	queue_free()
