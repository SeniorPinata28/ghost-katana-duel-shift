extends CharacterBody2D

@export var enemy_id := "grunt_01"
@export var max_health := 2
@export var speed := 74.0
@export var detection_range := 340.0
@export var attack_range := 46.0
@export var patrol_distance := 90.0

const GRAVITY := 980.0

var health := 2
var spawn_x := 0.0
var patrol_direction := 1.0
var attack_cooldown := 0.0
var player: CharacterBody2D = null

func _ready() -> void:
	if GameManager.defeated_ordinary_ids.has(enemy_id):
		queue_free()
		return
	health = max_health
	spawn_x = global_position.x
	add_to_group("ordinary_enemies_2d")
	player = get_tree().get_first_node_in_group("player_2d") as CharacterBody2D

func _physics_process(delta: float) -> void:
	var factor := GameManager.world_time_factor()
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta * factor)
	if is_instance_valid(player):
		var distance := player.global_position.x - global_position.x
		if absf(distance) <= detection_range:
			GameManager.alarm_level = maxi(GameManager.alarm_level, 1)
			velocity.x = sign(distance) * speed * factor
			if absf(distance) <= attack_range and attack_cooldown <= 0.0:
				_attack_player()
		else:
			_patrol(factor)
	else:
		_patrol(factor)
	move_and_slide()

func _patrol(factor: float) -> void:
	if absf(global_position.x - spawn_x) >= patrol_distance:
		patrol_direction = -sign(global_position.x - spawn_x)
	velocity.x = patrol_direction * speed * 0.42 * factor

func _attack_player() -> void:
	attack_cooldown = 1.05
	if is_instance_valid(player) and player.has_method("take_lethal_hit"):
		player.take_lethal_hit(sign(player.global_position.x - global_position.x))

func take_damage(amount: int, source: Node = null, _damage_type: String = "slash") -> void:
	health -= amount
	modulate = Color(1.0, 0.42, 0.42, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		GameManager.mark_ordinary_defeated(enemy_id)
		if is_instance_valid(source) and source.has_method("add_energy"):
			source.add_energy(24.0)
		SfxManager.play_cue("hit")
		queue_free()
