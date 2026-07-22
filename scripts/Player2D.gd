extends CharacterBody2D

signal status_changed(message: String)
signal player_died

const PROJECTILE_SCRIPT := preload("res://scripts/PlayerProjectile2D.gd")

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
	if existing is AnimatedSprite2D:
		player_visual = existing
		return
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
	_add_run_animation(frames)
	_add_sheet_animation(frames, &"jump", "res://assets/hero/source_sheets/hero_jump.png", 6, 10.0, false)
	_add_sheet_animation(frames, &"attack", "res://assets/hero/source_sheets/hero_attack.png", 6, 18.0, false)
	_add_sheet_animation(frames, &"heavy", "res://assets/hero/source_sheets/hero_heavy.png", 6, 14.0, false)
	_add_sheet_animation(frames, &"dash", "res://assets/hero/source_sheets/hero_dash.png", 6, 20.0, false)
	_add_sheet_animation(frames, &"death", "res://assets/hero/source_sheets/hero_death.png", 6, 10.0, false)
	return frames

func _add_run_animation(frames: SpriteFrames) -> void:
	frames.add_animation(&"run")
	frames.set_animation_speed(&"run", 11.0)
	frames.set_animation_loop(&"run", true)
	for index in range(1, 7):
		var path := "res://assets/hero/run_%02d.webp" % index
		var texture := load(path) as Texture2D
		if texture != null:
			frames.add_frame(&"run", texture)

func _add_sheet_animation(frames: SpriteFrames, animation_name: StringName, path: String, frame_count: int, fps: float, looped: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looped)
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var frame_width := texture.get_width() / frame_count
	var frame_height := texture.get_height()
	for index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(index * frame_width, 0, frame_width, frame_height)
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
		_release_wall_pressure()
		_update_animation(0.0)
		return
	if dash_time > 0.0:
		velocity = Vector2(facing * DASH_SPEED, 0.0)
		move_and_slide()
		_release_wall_pressure()
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
	if Input.is_action_just_pressed("technique"):
		use_technique()
	if Input.is_action_just_pressed("dash_focus"):
		request_dash()

	move_and_slide()
	_release_wall_pressure()
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
		SfxManager.play_cue("dash")
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		velocity.y = 0.0
		floor_snap_length = 6.0
		return
	var gravity := GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN
	velocity.y += gravity * delta

func _apply_horizontal_movement(direction: float, delta: float) -> void:
	var move_factor := 0.58 if attack_lock_time > 0.0 else 1.0
	var target_speed := direction * SPEED * move_factor
	if absf(direction) > 0.01:
		var acceleration := GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		var friction := GROUND_FRICTION if is_on_floor() else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _release_wall_pressure() -> void:
	if not is_on_wall():
		return
	var wall_normal := get_wall_normal()
	if wall_normal == Vector2.ZERO:
		return
	if velocity.dot(wall_normal) < 0.0:
		velocity -= wall_normal * velocity.dot(wall_normal)
	velocity.x += wall_normal.x * WALL_RELEASE_SPEED
	if not is_on_floor() and velocity.y > 0.0:
		velocity.y = maxf(velocity.y, 40.0)

func request_dash() -> void:
	if controls_locked or dead:
		return
	if dash_cooldown > 0.0:
		status_changed.emit("Рывок: перезарядка %.1f с" % dash_cooldown)
		return
	dash_time = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	invulnerability_time = DASH_DURATION + 0.05
	_damage_in_box(Vector2(82, 58), global_position + Vector2(facing * 48.0, 0.0), 1, "dash")
	_play_visual(&"dash")
	SfxManager.play_cue("dash")
	status_changed.emit("Рывок разрушает слабые объекты")

func quick_attack() -> void:
	if controls_locked or dead or quick_cooldown > 0.0:
		return
	quick_cooldown = QUICK_ATTACK_COOLDOWN
	attack_lock_time = 0.22
	_play_visual(&"attack")
	_damage_in_box(Vector2(96, 76), global_position + Vector2(facing * 54.0, -4.0), 1, "slash")
	SfxManager.play_cue("attack")
	status_changed.emit("Быстрый удар")

func strong_attack() -> void:
	if controls_locked or dead or strong_cooldown > 0.0:
		return
	strong_cooldown = STRONG_ATTACK_COOLDOWN
	attack_lock_time = 0.48
	_play_visual(&"heavy")
	_damage_in_box(Vector2(128, 92), global_position + Vector2(facing * 70.0, -2.0), 2, "heavy")
	SfxManager.play_cue("heavy")
	status_changed.emit("Сильный удар разрушает усиленные объекты")

func use_technique() -> void:
	if controls_locked or dead or technique_cooldown > 0.0:
		return
	var technique := GameManager.selected_technique
	var cost := 35.0 if technique == "blade" else 45.0
	if not GameManager.spend_special_energy(cost):
		status_changed.emit("Недостаточно энергии техники")
		return
	technique_cooldown = TECHNIQUE_COOLDOWN
	var projectile := PROJECTILE_SCRIPT.new()
	projectile.direction = facing
	projectile.owner_player = self
	if technique == "breaker":
		projectile.damage = 3
		projectile.damage_type = "explosive"
		projectile.explosive = true
		projectile.speed = 430.0
		status_changed.emit("Разрушитель: взрывной талисман")
	else:
		projectile.damage = 2
		projectile.damage_type = "energy"
		projectile.speed = 680.0
		status_changed.emit("Клинок: энергетический разрез")
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(facing * 38.0, -16.0)
	SfxManager.play_cue("attack")

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
		status_changed.emit("Защитная печать поглотила смертельный удар")
		return
	dead = true
	controls_locked = true
	GameManager.focus_active = false
	_play_visual(&"death")
	SfxManager.play_cue("hit")
	status_changed.emit("Смертельный удар. Возврат к контрольной точке")
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

func technique_name() -> String:
	return "РАЗРУШИТЕЛЬ" if GameManager.selected_technique == "breaker" else "КЛИНОК"

func _update_timers(delta: float) -> void:
	dash_time = maxf(0.0, dash_time - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	quick_cooldown = maxf(0.0, quick_cooldown - delta)
	strong_cooldown = maxf(0.0, strong_cooldown - delta)
	technique_cooldown = maxf(0.0, technique_cooldown - delta)
	invulnerability_time = maxf(0.0, invulnerability_time - delta)
	attack_lock_time = maxf(0.0, attack_lock_time - delta)
	jump_buffer_time = maxf(0.0, jump_buffer_time - delta)

func _update_focus(delta: float) -> void:
	if focus_requested and GameManager.special_energy > 0.0 and not dead:
		GameManager.focus_active = true
		GameManager.special_energy = maxf(0.0, GameManager.special_energy - FOCUS_DRAIN_PER_SECOND * delta)
		if GameManager.special_energy <= 0.0:
			focus_requested = false
			GameManager.focus_active = false
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
	var hits := get_world_2d().direct_space_state.intersect_shape(query, 32)
	var damaged: Dictionary = {}
	for hit in hits:
		var collider := hit.get("collider") as Node
		if collider == null or damaged.has(collider.get_instance_id()):
			continue
		damaged[collider.get_instance_id()] = true
		if collider.has_method("take_damage"):
			collider.take_damage(damage, self, damage_type)

func _play_visual(animation_name: StringName) -> void:
	if player_visual is AnimatedSprite2D:
		(player_visual as AnimatedSprite2D).play(animation_name)
	elif player_visual is Polygon2D:
		var polygon := player_visual as Polygon2D
		match animation_name:
			&"dash":
				polygon.scale = Vector2(1.35, 0.72)
			&"attack":
				polygon.scale = Vector2(1.18, 0.92)
			&"heavy":
				polygon.scale = Vector2(1.28, 1.08)
			&"death":
				polygon.rotation = PI * 0.5
				polygon.modulate = Color(0.45, 0.45, 0.45, 1.0)
			_:
				polygon.scale = Vector2.ONE
				polygon.rotation = 0.0
				polygon.modulate = Color.WHITE

func _current_visual_animation() -> StringName:
	if player_visual is AnimatedSprite2D:
		return (player_visual as AnimatedSprite2D).animation
	return &""

func _update_animation(direction: float) -> void:
	if absf(direction) > 0.01:
		player_visual.scale.x = absf(player_visual.scale.x) * (-1.0 if direction < 0.0 else 1.0)
	if dead:
		return
	if dash_time > 0.0:
		if _current_visual_animation() != &"dash":
			_play_visual(&"dash")
	elif attack_lock_time > 0.0:
		return
	elif not is_on_floor():
		if _current_visual_animation() != &"jump":
			_play_visual(&"jump")
	elif absf(direction) > 0.01:
		if _current_visual_animation() != &"run":
			_play_visual(&"run")
	else:
		if _current_visual_animation() != &"idle":
			_play_visual(&"idle")
