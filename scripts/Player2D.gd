extends CharacterBody2D

signal status_changed(message: String)
signal player_died

const TECHNIQUE_PROJECTILE := preload("res://scripts/PlayerProjectile2D.gd")
const GUN_PROJECTILE := preload("res://scripts/GunProjectile2D.gd")

const SPEED := 225.0
const GROUND_ACCELERATION := 1900.0
const AIR_ACCELERATION := 1250.0
const GROUND_FRICTION := 2300.0
const AIR_FRICTION := 520.0
const JUMP_VELOCITY := -430.0
const GRAVITY_UP := 980.0
const GRAVITY_DOWN := 1420.0
const JUMP_CUT_MULTIPLIER := 0.48
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12
const DASH_SPEED := 610.0
const DASH_DURATION := 0.17
const DASH_COOLDOWN := 0.90
const QUICK_ATTACK_COOLDOWN := 0.24
const STRONG_ATTACK_COOLDOWN := 0.62
const TECHNIQUE_COOLDOWN := 0.32
const GUN_COOLDOWN := 0.18
const RELOAD_TIME := 1.05
const MAGAZINE_SIZE := 8
const FOCUS_DRAIN_PER_SECOND := 24.0
const WALL_RELEASE_SPEED := 42.0

var facing := 1.0
var controls_locked := false
var dead := false
var dash_time := 0.0
var dash_cooldown := 0.0
var quick_cooldown := 0.0
var strong_cooldown := 0.0
var technique_cooldown := 0.0
var gun_cooldown := 0.0
var reload_time := 0.0
var ammo := MAGAZINE_SIZE
var invulnerability_time := 0.0
var attack_lock_time := 0.0
var coyote_time := 0.0
var jump_buffer_time := 0.0
var focus_requested := false
var player_visual: Node2D

func _ready() -> void:
	add_to_group("player_2d")
	floor_stop_on_slope = false
	floor_constant_speed = true
	floor_snap_length = 6.0
	safe_margin = 0.04
	_setup_player_visual()
	_play_visual(&"idle")

func _setup_player_visual() -> void:
	var existing := get_node_or_null("PlayerVisual") as Node2D
	var animated := AnimatedSprite2D.new()
	animated.name = "PlayerVisualAnimated"
	animated.centered = true
	animated.position = Vector2(0.0, -8.0)
	animated.scale = Vector2(0.20, 0.20)
	animated.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animated.sprite_frames = _build_player_frames()
	add_child(animated)
	player_visual = animated
	if existing != null:
		existing.visible = false

func _build_player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	_add_sheet_animation(frames, &"idle", "res://assets/hero/source_sheets/hero_ready.png", 6, 6.0, true)
	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 11.0)
	frames.set_animation_loop(&"run", true)
	for index in range(1, 7):
		var texture := load("res://assets/hero/run_%02d.webp" % index) as Texture2D
		if texture != null:
			frames.add_frame(&"run", texture)
	_add_sheet_animation(frames, &"jump", "res://assets/hero/source_sheets/hero_jump.png", 6, 10.0, false)
	_add_sheet_animation(frames, &"attack", "res://assets/hero/source_sheets/hero_attack.png", 6, 18.0, false)
	_add_sheet_animation(frames, &"heavy", "res://assets/hero/source_sheets/hero_heavy.png", 6, 14.0, false)
	_add_sheet_animation(frames, &"dash", "res://assets/hero/source_sheets/hero_dash.png", 6, 20.0, false)
	_add_sheet_animation(frames, &"death", "res://assets/hero/source_sheets/hero_death.png", 6, 10.0, false)
	return frames

func _add_sheet_animation(frames: SpriteFrames, animation_name: StringName, path: String, frame_count: int, fps: float, looped: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looped)
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var frame_width := texture.get_width() / frame_count
	for index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(index * frame_width, 0, frame_width, texture.get_height())
		frames.add_frame(animation_name, atlas)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_focus(delta)
	if dead:
		velocity = Vector2.ZERO
		return
	if controls_locked:
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
		_apply_gravity(delta)
		move_and_slide()
		return
	if dash_time > 0.0:
		velocity = Vector2(facing * DASH_SPEED, 0.0)
		move_and_slide()
		_update_animation(facing)
		return
	_update_ground_state(delta)
	_handle_jump_input()
	_apply_gravity(delta)
	var direction := Input.get_axis("move_left", "move_right")
	if absf(direction) > 0.01:
		facing = sign(direction)
	_apply_horizontal_movement(direction, delta)
	if Input.is_action_just_pressed("attack"):
		quick_attack()
	if Input.is_action_just_pressed("shoot"):
		shoot_gun()
	if Input.is_action_just_pressed("technique"):
		use_technique()
	if Input.is_action_just_pressed("dash_focus"):
		request_dash()
	move_and_slide()
	_update_animation(direction)

func _update_ground_state(delta: float) -> void:
	if is_on_floor():
		coyote_time = COYOTE_TIME
	else:
		coyote_time = maxf(0.0, coyote_time - delta)

func _handle_jump_input() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_time = JUMP_BUFFER_TIME
	if jump_buffer_time > 0.0 and coyote_time > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_time = 0.0
		coyote_time = 0.0
		floor_snap_length = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		velocity.y = 0.0
		floor_snap_length = 6.0
		return
	velocity.y += (GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN) * delta

func _apply_horizontal_movement(direction: float, delta: float) -> void:
	var target_speed := direction * SPEED * (0.58 if attack_lock_time > 0.0 else 1.0)
	if absf(direction) > 0.01:
		velocity.x = move_toward(velocity.x, target_speed, (GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION) * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, (GROUND_FRICTION if is_on_floor() else AIR_FRICTION) * delta)

func request_dash() -> void:
	if controls_locked or dead or dash_cooldown > 0.0:
		return
	dash_time = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	invulnerability_time = DASH_DURATION + 0.05
	_damage_in_box(Vector2(82, 58), global_position + Vector2(facing * 48.0, 0.0), 1, "dash")
	_play_visual(&"dash")
	status_changed.emit("Рывок")

func quick_attack() -> void:
	if controls_locked or dead or quick_cooldown > 0.0:
		return
	quick_cooldown = QUICK_ATTACK_COOLDOWN
	attack_lock_time = 0.22
	_play_visual(&"attack")
	_damage_in_box(Vector2(96, 76), global_position + Vector2(facing * 54.0, -4.0), 1, "slash")
	status_changed.emit("Быстрый удар")

func strong_attack() -> void:
	if controls_locked or dead or strong_cooldown > 0.0:
		return
	strong_cooldown = STRONG_ATTACK_COOLDOWN
	attack_lock_time = 0.48
	_play_visual(&"heavy")
	_damage_in_box(Vector2(128, 92), global_position + Vector2(facing * 70.0, -2.0), 2, "heavy")
	status_changed.emit("Сильный удар")

func shoot_gun() -> void:
	if controls_locked or dead or gun_cooldown > 0.0 or reload_time > 0.0:
		return
	if ammo <= 0:
		_start_reload()
		return
	ammo -= 1
	gun_cooldown = GUN_COOLDOWN
	var bullet := GUN_PROJECTILE.new()
	bullet.direction = facing
	bullet.owner_player = self
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(facing * 36.0, -14.0)
	status_changed.emit("Пистолет: %d/%d" % [ammo, MAGAZINE_SIZE])
	if ammo <= 0:
		_start_reload()

func _start_reload() -> void:
	if reload_time > 0.0:
		return
	reload_time = RELOAD_TIME
	status_changed.emit("Перезарядка")

func use_technique() -> void:
	if controls_locked or dead or technique_cooldown > 0.0:
		return
	var technique := GameManager.selected_technique
	var cost := 35.0 if technique == "blade" else 45.0
	if not GameManager.spend_special_energy(cost):
		status_changed.emit("Недостаточно энергии техники")
		return
	technique_cooldown = TECHNIQUE_COOLDOWN
	var projectile := TECHNIQUE_PROJECTILE.new()
	projectile.direction = facing
	projectile.owner_player = self
	if technique == "breaker":
		projectile.damage = 3
		projectile.damage_type = "explosive"
		projectile.explosive = true
		projectile.speed = 430.0
	else:
		projectile.damage = 2
		projectile.damage_type = "energy"
		projectile.speed = 680.0
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(facing * 38.0, -16.0)
	status_changed.emit("Техника: %s" % technique_name())

func set_focus_requested(active: bool) -> void:
	focus_requested = active
	if not active:
		GameManager.focus_active = false

func take_lethal_hit(hit_direction: float = 0.0) -> void:
	if dead or invulnerability_time > 0.0:
		return
	if GameManager.consume_seal():
		invulnerability_time = 1.1
		velocity.x = hit_direction * 260.0
		status_changed.emit("Печать поглотила смертельный удар")
		return
	dead = true
	controls_locked = true
	GameManager.focus_active = false
	_play_visual(&"death")
	player_died.emit()
	_restart_after_death.call_deferred()

func _restart_after_death() -> void:
	await get_tree().create_timer(0.75).timeout
	GameManager.restart_from_checkpoint()

func add_energy(amount: float) -> void:
	GameManager.add_special_energy(amount)

func show_status(message: String) -> void:
	status_changed.emit(message)

func get_dash_text() -> String:
	return "РЫВОК/ФОКУС" if dash_cooldown <= 0.0 else "РЫВОК %.1f" % dash_cooldown

func get_gun_text() -> String:
	if reload_time > 0.0:
		return "ПИСТОЛЕТ\nПЕРЕЗАРЯДКА"
	return "ПИСТОЛЕТ\n%d/%d" % [ammo, MAGAZINE_SIZE]

func technique_name() -> String:
	return "РАЗРУШИТЕЛЬ" if GameManager.selected_technique == "breaker" else "КЛИНОК"

func _update_timers(delta: float) -> void:
	dash_time = maxf(0.0, dash_time - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	quick_cooldown = maxf(0.0, quick_cooldown - delta)
	strong_cooldown = maxf(0.0, strong_cooldown - delta)
	technique_cooldown = maxf(0.0, technique_cooldown - delta)
	gun_cooldown = maxf(0.0, gun_cooldown - delta)
	invulnerability_time = maxf(0.0, invulnerability_time - delta)
	attack_lock_time = maxf(0.0, attack_lock_time - delta)
	jump_buffer_time = maxf(0.0, jump_buffer_time - delta)
	if reload_time > 0.0:
		reload_time = maxf(0.0, reload_time - delta)
		if reload_time <= 0.0:
			ammo = MAGAZINE_SIZE
			status_changed.emit("Пистолет перезаряжен")

func _update_focus(delta: float) -> void:
	if focus_requested and GameManager.special_energy > 0.0 and not dead:
		GameManager.focus_active = true
		GameManager.special_energy = maxf(0.0, GameManager.special_energy - FOCUS_DRAIN_PER_SECOND * delta)
	else:
		GameManager.focus_active = false

func _damage_in_box(size: Vector2, center: Vector2, damage: int, damage_type: String) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var damaged: Dictionary = {}
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 32):
		var collider := hit.get("collider") as Node
		if collider == null or damaged.has(collider.get_instance_id()):
			continue
		damaged[collider.get_instance_id()] = true
		if collider.has_method("take_damage"):
			collider.take_damage(damage, self, damage_type)

func _play_visual(animation_name: StringName) -> void:
	if player_visual is AnimatedSprite2D:
		(player_visual as AnimatedSprite2D).play(animation_name)

func _update_animation(direction: float) -> void:
	if absf(direction) > 0.01:
		player_visual.scale.x = absf(player_visual.scale.x) * (-1.0 if direction < 0.0 else 1.0)
	if dead:
		return
	if dash_time > 0.0:
		_play_visual(&"dash")
	elif attack_lock_time > 0.0:
		return
	elif not is_on_floor():
		_play_visual(&"jump")
	elif absf(direction) > 0.01:
		_play_visual(&"run")
	else:
		_play_visual(&"idle")
