extends Area2D

var direction := 1.0
var damage := 1
var speed := 920.0
var life_time := 1.2
var owner_player: Node = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 4)
	shape_node.shape = shape
	add_child(shape_node)
	var visual := Polygon2D.new()
	visual.color = Color(1.0, 0.82, 0.28, 1.0)
	visual.polygon = PackedVector2Array([Vector2(-8, -2), Vector2(8, -2), Vector2(8, 2), Vector2(-8, 2)])
	add_child(visual)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	life_time -= delta
	if life_time <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == owner_player:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, owner_player, "bullet")
	queue_free()
