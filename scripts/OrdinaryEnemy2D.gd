extends CharacterBody2D

@export var max_health := 3
@export var speed := 62.0
@export var contact_damage := 1

const GRAVITY := 980.0

var health := 3
var attack_cooldown := 0.0
var player: CharacterBody2D = null

func _ready() -> void:
	health = max_health
	add_to_group("ordinary_enemies_2d")
	player = get_tree().get_first_node_in_group("player_2d") as CharacterBody2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	attack_cooldown = max(0.0, attack_cooldown - delta)
	if is_instance_valid(player) and abs(player.global_position.x - global_position.x) < 300.0:
		velocity.x = sign(player.global_position.x - global_position.x) * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 4.0 * delta)

	move_and_slide()

	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		if collision.get_collider() == player and attack_cooldown <= 0.0:
			player.take_hit(contact_damage, sign(player.global_position.x - global_position.x))
			attack_cooldown = 0.9

func take_damage(amount: int, source: Node = null) -> void:
	health -= amount
	modulate = Color(1.0, 0.45, 0.45, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		if is_instance_valid(source) and source.has_method("add_rage"):
			source.add_rage(35)
		queue_free()
