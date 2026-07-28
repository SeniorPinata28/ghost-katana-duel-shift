extends Area2D

var direction := 1.0
var damage := 1
var damage_type := "energy"
var speed := 620.0
var life_time := 1.6
var owner_player: Node = null
var explosive := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 10)
	shape_node.shape = shape
	add_child(shape_node)
	var visual := Polygon2D.new()
	visual.color = Color(0.15, 0.88, 1.0, 1.0) if not explosive else Color(1.0, 0.42, 0.12, 1.0)
	visual.polygon = PackedVector2Array([Vector2(-12, -5), Vector2(12, -5), Vector2(12, 5), Vector2(-12, 5)])
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
	if explosive:
		_explode()
	elif body.has_method("take_damage"):
		body.take_damage(damage, owner_player, damage_type)
	queue_free()

func _explode() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 76.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 1
	if is_instance_valid(owner_player) and owner_player is CollisionObject2D:
		query.exclude = [(owner_player as CollisionObject2D).get_rid()]
	var hits := get_world_2d().direct_space_state.intersect_shape(query, 32)
	for hit in hits:
		var collider := hit.get("collider") as Node
		if collider != null and collider.has_method("take_damage"):
			collider.take_damage(damage, owner_player, "explosive")
	SfxManager.play_cue("break")
