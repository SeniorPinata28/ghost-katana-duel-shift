extends CharacterBody2D

const PROJECTILE_SCRIPT := preload("res://scripts/EnemyProjectile2D.gd")
const GRAVITY := 980.0

@export var enemy_id := "archer_01"
@export var max_health := 2
@export var detection_range := 560.0
@export var fire_interval := 1.55

var health := 2
var fire_cooldown := 0.7
var player: CharacterBody2D = null

func _ready() -> void:
	if GameManager.defeated_ordinary_ids.has(enemy_id):
		queue_free()
		return
	health = max_health
	add_to_group("ordinary_enemies_2d")
	player = get_tree().get_first_node_in_group("player_2d") as CharacterBody2D

func _physics_process(delta: float) -> void:
	var factor := GameManager.world_time_factor()
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	fire_cooldown = maxf(0.0, fire_cooldown - delta * factor)
	if is_instance_valid(player):
		var distance := player.global_position.x - global_position.x
		if absf(distance) <= detection_range and fire_cooldown <= 0.0:
			GameManager.alarm_level = maxi(GameManager.alarm_level, 1)
			_fire(sign(distance))
	move_and_slide()

func _fire(direction: float) -> void:
	fire_cooldown = fire_interval
	var projectile := PROJECTILE_SCRIPT.new()
	projectile.direction = direction
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(direction * 28.0, -18.0)

func take_damage(amount: int, source: Node = null, _damage_type: String = "slash") -> void:
	health -= amount
	modulate = Color(1.0, 0.42, 0.42, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		GameManager.mark_ordinary_defeated(enemy_id)
		if is_instance_valid(source) and source.has_method("add_energy"):
			source.add_energy(28.0)
		SfxManager.play_cue("hit")
		queue_free()
