extends CharacterBody2D

signal status_changed(message: String)

const BULLET_SCRIPT := preload("res://scripts/Bullet2D.gd")

const SPEED := 220.0
const JUMP_VELOCITY := -420.0
const GRAVITY := 980.0
const DASH_SPEED := 560.0
const DASH_DURATION := 0.16
const DASH_COOLDOWN := 1.15
const MELEE_COOLDOWN := 0.32
const SHOOT_COOLDOWN := 0.24
const BERSERK_DURATION := 6.0

var facing := 1.0
var dash_time := 0.0
var dash_cooldown := 0.0
var melee_cooldown := 0.0
var shoot_cooldown := 0.0
var invulnerability_time := 0.0

var max_health := 3
var health := 3
var rage := 0
var berserk_unlocked := false
var berserk_time := 0.0

@onready var player_visual: AnimatedSprite2D = $PlayerVisual

func _ready() -> void:
	add_to_group("player_2d")
	player_visual.play(&"run")
	player_visual.pause()
	player_visual.frame = 0

func _physics_process(delta: float) -> void:
	_update_timers(delta)

	if dash_time > 0.0:
		velocity = Vector2(facing * DASH_SPEED, 0.0)
		move_and_slide()
		_update_animation(facing)
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var direction := Input.get_axis("ui_left", "ui_right")
	if abs(direction) > 0.01:
		facing = sign(direction)
	velocity.x = direction * (SPEED * 1.25 if is_berserk() else SPEED)

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()
	_update_animation(direction)

func request_dash() -> void:
	if dash_cooldown > 0.0:
		status_changed.emit("Рывок перезаряжается: %.1f с" % dash_cooldown)
		return
	dash_time = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	invulnerability_time = DASH_DURATION
	_damage_in_box(Vector2(76, 54), global_position + Vector2(facing * 46.0, 0.0), 2 if is_berserk() else 1)
	status_changed.emit("Рывок!")

func melee_attack() -> void:
	if melee_cooldown > 0.0:
		return
	melee_cooldown = MELEE_COOLDOWN
	var damage := 2 if is_berserk() else 1
	_damage_in_box(Vector2(92, 72), global_position + Vector2(facing * 52.0, 0.0), damage)
	status_changed.emit("Ближний удар")

func shoot() -> void:
	if shoot_cooldown > 0.0:
		return
	shoot_cooldown = SHOOT_COOLDOWN
	var bullet := BULLET_SCRIPT.new()
	bullet.direction = facing
	bullet.damage = 2 if is_berserk() else 1
	bullet.owner_player = self
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(facing * 34.0, -10.0)
	status_changed.emit("Выстрел")

func add_rage(amount: int) -> void:
	rage = clampi(rage + amount, 0, 100)
	status_changed.emit("Ярость: %d%%" % rage)

func unlock_berserk() -> void:
	berserk_unlocked = true
	status_changed.emit("Пленный спасён: режим берсерка открыт")

func activate_berserk() -> void:
	if not berserk_unlocked:
		status_changed.emit("Сначала освободите пленного")
		return
	if rage < 100:
		status_changed.emit("Для берсерка нужно 100% ярости")
		return
	rage = 0
	berserk_time = BERSERK_DURATION
	invulnerability_time = BERSERK_DURATION
	status_changed.emit("БЕРСЕРК: скорость и урон увеличены")

func is_berserk() -> bool:
	return berserk_time > 0.0

func take_hit(amount: int, hit_direction: float = 0.0) -> void:
	if invulnerability_time > 0.0:
		return
	health -= amount
	invulnerability_time = 0.65
	velocity.x = hit_direction * 220.0
	status_changed.emit("Получен урон. HP: %d/%d" % [maxi(health, 0), max_health])
	if health <= 0:
		status_changed.emit("Герой побеждён")
		GameManager.reset_run.call_deferred()

func get_dash_text() -> String:
	if dash_cooldown <= 0.0:
		return "РЫВОК"
	return "РЫВОК %.1f" % dash_cooldown

func get_berserk_text() -> String:
	if is_berserk():
		return "БЕРСЕРК %.1f" % berserk_time
	if not berserk_unlocked:
		return "БЕРСЕРК 🔒"
	return "БЕРСЕРК %d%%" % rage

func _update_timers(delta: float) -> void:
	dash_time = max(0.0, dash_time - delta)
	dash_cooldown = max(0.0, dash_cooldown - delta)
	melee_cooldown = max(0.0, melee_cooldown - delta)
	shoot_cooldown = max(0.0, shoot_cooldown - delta)
	invulnerability_time = max(0.0, invulnerability_time - delta)
	berserk_time = max(0.0, berserk_time - delta)
	player_visual.modulate = Color(1.0, 0.35, 0.25, 1.0) if is_berserk() else Color.WHITE

func _damage_in_box(size: Vector2, center: Vector2, damage: int) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hits := get_world_2d().direct_space_state.intersect_shape(query, 24)
	for hit in hits:
		var collider := hit["collider"] as Node
		if collider != null and collider.has_method("take_damage"):
			collider.take_damage(damage, self)

func _update_animation(direction: float) -> void:
	if abs(direction) > 0.01:
		player_visual.flip_h = direction < 0.0

	if dash_time > 0.0:
		player_visual.pause()
		player_visual.frame = 5
	elif not is_on_floor():
		player_visual.pause()
		player_visual.frame = 2
	elif abs(direction) > 0.01:
		if not player_visual.is_playing():
			player_visual.play(&"run")
	else:
		player_visual.pause()
		player_visual.frame = 0
