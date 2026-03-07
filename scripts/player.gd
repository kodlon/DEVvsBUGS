extends CharacterBody2D

signal burnout_changed(current: float, maximum: float)
signal player_died

var burnout: float = 0.0
var _shoot_timer: float = 0.0
var _bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
var _arena_min: Vector2
var _arena_max: Vector2

# Скіли
var passive_skill: PassiveSkillBase = null
var active_skill_1: ActiveSkillBase = null
var active_skill_2: ActiveSkillBase = null

# Додж
var _is_dashing := false
var _dash_direction := Vector2.UP
var _dash_timer := 0.0
var _original_collision_mask: int
var _original_color: Color

func _ready() -> void:
	add_to_group("player")
	_original_color = $Visual.color
	var offset := GameConfig.get_arena_offset()
	var h := GameConfig.PLAYER_HALF_SIZE
	_arena_min = offset + Vector2(h, h)
	_arena_max = offset + Vector2(GameConfig.ARENA_WIDTH - h, GameConfig.ARENA_HEIGHT - h)
	_original_collision_mask = collision_mask
	_setup_skills()

	var backend_timer := Timer.new()
	backend_timer.wait_time = 1.0
	backend_timer.autostart = true
	backend_timer.timeout.connect(_on_backend_timer)
	add_child(backend_timer)

func _on_backend_timer() -> void:
	if PlayerStats.backend_blame_dps > 0.0:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var dir = (enemy.global_position - global_position).normalized()
			enemy.take_damage(PlayerStats.backend_blame_dps, dir)

func _setup_skills() -> void:
	active_skill_1 = preload("res://scripts/skills/active/skill_dodge.gd").new()
	active_skill_1.name = "SkillDodge"
	add_child(active_skill_1)

	active_skill_2 = preload("res://scripts/skills/active/skill_empty.gd").new()
	active_skill_2.name = "SkillEmpty"
	add_child(active_skill_2)

	passive_skill = preload("res://scripts/skills/passive/skill_rubber_duck.gd").new()
	passive_skill.name = "SkillRubberDuck"
	add_child(passive_skill)
	passive_skill.apply(self)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_X:
				if active_skill_1:
					active_skill_1.activate(self)
			KEY_C:
				if active_skill_2:
					active_skill_2.activate(self)

func _physics_process(delta: float) -> void:
	queue_redraw()
	if _is_dashing:
		_handle_dash(delta)
	else:
		_handle_movement()
		_handle_shooting(delta)

func _handle_movement() -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_up"):    direction.y -= 1
	if Input.is_action_pressed("ui_down"):  direction.y += 1
	if Input.is_action_pressed("ui_left"):  direction.x -= 1
	if Input.is_action_pressed("ui_right"): direction.x += 1
	if Input.is_key_pressed(KEY_W): direction.y -= 1
	if Input.is_key_pressed(KEY_S): direction.y += 1
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_D): direction.x += 1

	velocity = direction.normalized() * PlayerStats.move_speed
	move_and_slide()
	position = position.clamp(_arena_min, _arena_max)

func _handle_dash(delta: float) -> void:
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_is_dashing = false
		collision_mask = _original_collision_mask
	else:
		velocity = _dash_direction * DodgeConfig.DASH_SPEED
		move_and_slide()
		position = position.clamp(_arena_min, _arena_max)

func _handle_shooting(delta: float) -> void:
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_auto_shoot()
		_shoot_timer = PlayerStats.fire_rate_delay

func _auto_shoot() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var radius := PlayerStats.attack_range
	var spread_magnitude = PlayerStats.weapon_spread
	
	if PlayerStats.has_second_monitor:
		# Стріляємо з двох "моніторів" (гармат) - зліва і справа
		var offsets = [Vector2(-20, 0), Vector2(20, 0)]
		for offset in offsets:
			var gun_pos = global_position + offset
			var nearest: Node2D = null
			var min_dist := INF
			
			for enemy in enemies:
				var dist: float = gun_pos.distance_to(enemy.global_position)
				if radius > 0.0 and dist > radius:
					continue
				if dist < min_dist:
					min_dist = dist
					nearest = enemy
					
			if nearest != null:
				var bullet = _bullet_scene.instantiate()
				get_parent().add_child(bullet)
				bullet.global_position = gun_pos
				var base_direction: Vector2 = (nearest.global_position - gun_pos).normalized()
				var spread = deg_to_rad(spread_magnitude * randf_range(-1.0, 1.0))
				bullet.direction = base_direction.rotated(spread)
				get_tree().call_group("camera_shake", "shake_micro", bullet.direction)
				AudioManager.play_shoot()
	else:
		# Звичайна механіка - одна центральна гармата
		var nearest: Node2D = null
		var min_dist := INF
		
		for enemy in enemies:
			var dist: float = global_position.distance_to(enemy.global_position)
			if radius > 0.0 and dist > radius:
				continue
			if dist < min_dist:
				min_dist = dist
				nearest = enemy
				
		if nearest != null:
			var bullet = _bullet_scene.instantiate()
			get_parent().add_child(bullet)
			bullet.global_position = global_position
			var base_direction: Vector2 = (nearest.global_position - global_position).normalized()
			var spread = deg_to_rad(spread_magnitude * randf_range(-1.0, 1.0))
			bullet.direction = base_direction.rotated(spread)
			get_tree().call_group("camera_shake", "shake_micro", bullet.direction)
			AudioManager.play_shoot()

## Ворог наносить вигорання — ігнорується під час доджу
func take_burnout(amount: float) -> void:
	if _is_dashing:
		return
	amount *= PlayerStats.enemy_damage_mult
	burnout = clamp(burnout + amount, 0.0, PlayerStats.max_burnout)
	burnout_changed.emit(burnout, PlayerStats.max_burnout)
	get_tree().call_group("camera_shake", "shake_hard")
	AudioManager.play_received_damage()
	
	# Hit Flash
	var tween = create_tween()
	$Visual.color = Color(1.0, 0.1, 0.1) # Reddish
	tween.tween_property($Visual, "color", _original_color, 0.5).set_trans(Tween.TRANS_SINE)
	
	if burnout >= PlayerStats.max_burnout:
		player_died.emit()

## Пасивний скіл знімає вигорання
func reduce_burnout(amount: float) -> void:
	burnout = clamp(burnout - amount, 0.0, PlayerStats.max_burnout)
	burnout_changed.emit(burnout, PlayerStats.max_burnout)

## Викликається скілом Dodge
func start_dash() -> void:
	var dir := velocity.normalized()
	if dir.length() < 0.1:
		dir = Vector2.UP
	_dash_direction = dir
	_dash_timer = DodgeConfig.DASH_DURATION
	_is_dashing = true
	_original_collision_mask = collision_mask
	collision_mask = 0

func _draw() -> void:
	if PlayerStats.aura_range > 0.0:
		draw_circle(Vector2.ZERO, PlayerStats.aura_range, Color(0.6, 0.0, 1.0, 0.2))
		
	# Малюємо маленькі червоні гармати, якщо є другий "монітор" (або одну базову).
	var gun_color = Color(1.0, 0.2, 0.2, 0.9)
	if PlayerStats.has_second_monitor:
		draw_circle(Vector2(-20, 0), 4.0, gun_color)
		draw_circle(Vector2(20, 0), 4.0, gun_color)
	else:
		draw_circle(Vector2.ZERO, 4.0, gun_color)
