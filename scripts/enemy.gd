class_name Enemy
extends CharacterBody2D

# Типи ворогів — дзеркалить ключі GameConfig.ENEMY_CONFIG
const TYPE_NORMAL  := 0  # Junior's Typo
const TYPE_FAST    := 1  # Hotfix
const TYPE_TANK    := 2  # Legacy Code
const TYPE_TURRET  := 3  # Toxic Reviewer
const TYPE_COFFEE  := 4  # Coffee Scarab

var enemy_type: int = TYPE_NORMAL
var _player: Node2D = null
var _health: float = 25.0
var _speed: float = 160.0
var _burnout_damage: float = 6.0
var _base_scale: float = 1.0
var _damage_timer: float = 0.0
var _damage_accumulator: float = 0.0

# Зовнішній імпульс (для відштовхування від танку)
var _ext_vel: Vector2 = Vector2.ZERO

# Сповільнення від аури гравця (скидається щокадр)
var _aura_slow_mult: float = 1.0

# FAST — зиґзаґ
var _zigzag_time: float = 0.0

# TANK — таймер перевірки відштовхування
var _push_timer: float = 0.0

# TURRET — стан і вогонь
var _turret_fire_timer: float = 0.0
var _turret_fire_delay: float = 3.0
var _turret_stop_range: float = 180.0
var _acid_speed: float = 280.0
var _acid_damage: float = 12.0
var _acid_bullet_scene: PackedScene = preload("res://scenes/acid_bullet.tscn")

# COFFEE — блукання і втеча
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _flee_range: float = 200.0
var _heal_amount: float = 35.0
var _health_pickup_scene: PackedScene = preload("res://scenes/health_pickup.tscn")
var _floating_text_scene: PackedScene = preload("res://scenes/ui/floating_text.tscn")

# Walk Animation
var _walk_tween: Tween
var _step_side: int = 1
var _is_animating_to_idle: bool = false
var _step_duration: float = 0.2

## Викликати одразу після instantiate(), до add_child()
func setup(type: int) -> void:
	enemy_type = type
	var cfg: Dictionary = GameConfig.ENEMY_CONFIG[type]

	_health         = randf_range(cfg.hp_min,      cfg.hp_max)    * PlayerStats.enemy_hp_mult
	_speed          = randf_range(cfg.speed_min,   cfg.speed_max) * PlayerStats.enemy_speed_mult
	_burnout_damage = randf_range(cfg.burnout_min, cfg.burnout_max)
	_base_scale     = cfg.base_scale

	scale = Vector2.ZERO
	$Visual.color = cfg.color

	match type:
		TYPE_NORMAL:
			_step_duration = 0.2
		TYPE_FAST:
			_step_duration = 0.1
		TYPE_TANK:
			_step_duration = 0.35
		TYPE_TURRET:
			_step_duration = 0.25
		TYPE_COFFEE:
			_step_duration = 0.15

	# Squash & Stretch spawn
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 0.5) * _base_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * _base_scale, 0.15).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

	match type:
		TYPE_FAST:
			_zigzag_time = randf_range(0.0, TAU)
		TYPE_TURRET:
			_turret_fire_delay = randf_range(cfg.fire_delay_min, cfg.fire_delay_max)
			_turret_fire_timer = _turret_fire_delay
			_turret_stop_range = cfg.stop_range
			_acid_speed  = randf_range(cfg.acid_speed_min,  cfg.acid_speed_max)
			_acid_damage = randf_range(cfg.acid_damage_min, cfg.acid_damage_max)
		TYPE_COFFEE:
			_flee_range   = cfg.flee_range
			_heal_amount  = randf_range(cfg.heal_min, cfg.heal_max)
			_wander_timer = cfg.wander_change_time
			_wander_target = _get_random_arena_pos()

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		return

	match enemy_type:
		TYPE_NORMAL: _behave_normal()
		TYPE_FAST:   _behave_fast(delta)
		TYPE_TANK:   _behave_tank(delta)
		TYPE_TURRET: _behave_turret(delta)
		TYPE_COFFEE: _behave_coffee(delta)

	# Додаємо зовнішній імпульс (відштовхування) і затухаємо його
	velocity += _ext_vel
	_ext_vel = _ext_vel.move_toward(Vector2.ZERO, 400.0 * delta)
	# Аура качечки сповільнює ворогів
	velocity *= _aura_slow_mult
	_aura_slow_mult = 1.0  # скидаємо для наступного кадру
	move_and_slide()
	
	var is_moving := velocity.length_squared() > 10.0
	_update_walk_animation(is_moving)

	# Дотикова шкода (тільки для NORMAL, FAST, TANK)
	if enemy_type != TYPE_TURRET and enemy_type != TYPE_COFFEE:
		_damage_timer -= delta
		if _damage_timer <= 0.0:
			var dist: float = global_position.distance_to(_player.global_position)
			if dist < GameConfig.ENEMY_DAMAGE_RANGE * _base_scale:
				_player.call("take_burnout", _burnout_damage)
				_damage_timer = GameConfig.ENEMY_DAMAGE_INTERVAL

# ── Поведінки ──────────────────────────────────────────────

func _behave_normal() -> void:
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * _speed

func _behave_fast(delta: float) -> void:
	_zigzag_time += delta
	var dir := (_player.global_position - global_position).normalized()
	var perp := Vector2(-dir.y, dir.x)
	velocity = (dir + perp * sin(_zigzag_time * 5.0) * 0.6).normalized() * _speed

func _behave_tank(delta: float) -> void:
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * _speed

	_push_timer -= delta
	if _push_timer <= 0.0:
		_push_timer = 0.15
		var push_range: float = 30.0 * _base_scale
		for node in get_tree().get_nodes_in_group("enemies"):
			if node == self:
				continue
			var e: Enemy = node as Enemy
			if e == null:
				continue
			if e.enemy_type == TYPE_NORMAL or e.enemy_type == TYPE_FAST:
				var dist: float = global_position.distance_to(e.global_position)
				if dist < push_range and dist > 0.01:
					var push_dir: Vector2 = (e.global_position - global_position).normalized()
					e.apply_push(push_dir * 120.0)

func _behave_turret(delta: float) -> void:
	var dist: float = global_position.distance_to(_player.global_position)

	if dist > _turret_stop_range:
		# Наближається — рухаємося до гравця, скидаємо таймер касту
		var dir := (_player.global_position - global_position).normalized()
		velocity = dir * _speed
		_turret_fire_timer = _turret_fire_delay
		scale = Vector2.ONE * _base_scale
	else:
		# Каст — стоїмо, плавно зменшуємося, чекаємо пострілу
		velocity = Vector2.ZERO
		_turret_fire_timer -= delta
		var progress: float = clamp(1.0 - (_turret_fire_timer / _turret_fire_delay), 0.0, 1.0)
		scale = Vector2.ONE * lerpf(_base_scale, _base_scale * 0.65, progress)

		if _turret_fire_timer <= 0.0:
			scale = Vector2.ONE * _base_scale  # різкий snap назад
			_shoot_acid()
			_turret_fire_delay = randf_range(
				GameConfig.ENEMY_CONFIG[TYPE_TURRET].fire_delay_min,
				GameConfig.ENEMY_CONFIG[TYPE_TURRET].fire_delay_max
			)
			_turret_fire_timer = _turret_fire_delay

func _shoot_acid() -> void:
	if _player == null:
		return
	var bullet: AcidBullet = _acid_bullet_scene.instantiate() as AcidBullet
	var dir: Vector2 = (_player.global_position - global_position).normalized()
	bullet.setup(dir, _acid_speed, _acid_damage)
	get_parent().add_child(bullet)
	bullet.global_position = global_position

func _behave_coffee(delta: float) -> void:
	var dist: float = global_position.distance_to(_player.global_position)
	if dist < _flee_range:
		# Тікає від гравця
		var flee_dir: Vector2 = (global_position - _player.global_position).normalized()
		velocity = flee_dir * _speed
	else:
		# Хаотичне блукання
		_wander_timer -= delta
		if _wander_timer <= 0.0 or global_position.distance_to(_wander_target) < 10.0:
			_wander_target = _get_random_arena_pos()
			_wander_timer = GameConfig.ENEMY_CONFIG[TYPE_COFFEE].wander_change_time
		var to_wander: Vector2 = _wander_target - global_position
		if to_wander.length_squared() > 1.0:
			velocity = to_wander.normalized() * _speed * 0.5
		else:
			velocity = Vector2.ZERO

func _get_random_arena_pos() -> Vector2:
	var offset: Vector2 = GameConfig.get_arena_offset()
	return Vector2(
		randf_range(offset.x + 10.0, offset.x + GameConfig.ARENA_WIDTH  - 10.0),
		randf_range(offset.y + 10.0, offset.y + GameConfig.ARENA_HEIGHT - 10.0)
	)

## Зовнішній поштовх від танку
func apply_push(impulse: Vector2) -> void:
	_ext_vel += impulse

func take_damage(amount: float, hit_dir: Vector2 = Vector2.ZERO, source: String = "") -> void:
	_health -= amount
	AudioManager.play_enemy_hit()
	
	# Hit Flash
	var original_color = GameConfig.ENEMY_CONFIG[enemy_type].color
	var tween = create_tween()
	$Visual.color = Color.RED
	tween.tween_interval(0.08)
	tween.tween_property($Visual, "color", original_color, 0.0)
	
	# Knockback
	if hit_dir != Vector2.ZERO:
		apply_push(hit_dir * 100.0) # Knockback impulse
		
	# Floating Text
	var display_amount = 0.0
	var final_source = source
	if amount >= 1.0:
		display_amount = amount
	else:
		_damage_accumulator += amount
		if _damage_accumulator >= 1.0:
			display_amount = floor(_damage_accumulator)
			_damage_accumulator -= display_amount
			final_source = "aura" # Small damage is accumulated from aura
	
	if display_amount > 0 and _floating_text_scene:
		var text_node = _floating_text_scene.instantiate() as FloatingText
		text_node.global_position = global_position
		get_parent().add_child(text_node)
		text_node.setup(display_amount, _health <= 0.0, final_source)
	
	if _health <= 0.0:
		get_tree().call_group("camera_shake", "shake_light")
		get_tree().call_group("score_tracker", "add_score",
				int(GameConfig.ENEMY_CONFIG[enemy_type].score_value))
		PlayerStats.add_xp(GameConfig.XP_PER_ENEMY[enemy_type])
		if enemy_type == TYPE_COFFEE:
			_drop_health_pickup()
		queue_free()

func _drop_health_pickup() -> void:
	var pickup: HealthPickup = _health_pickup_scene.instantiate() as HealthPickup
	pickup.setup(_heal_amount)
	get_parent().add_child(pickup)
	pickup.global_position = global_position

func _update_walk_animation(is_moving: bool) -> void:
	if is_moving:
		_is_animating_to_idle = false
		if _walk_tween == null or not _walk_tween.is_valid():
			_walk_tween = create_tween()
			var angle_deg: float = randf_range(7.0, 10.0) * _step_side
			_walk_tween.tween_property($Visual, "rotation_degrees", angle_deg, _step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_walk_tween.tween_callback(func(): _step_side *= -1)
	else:
		if not _is_animating_to_idle:
			if _walk_tween and _walk_tween.is_valid():
				_walk_tween.kill()
			_walk_tween = create_tween()
			_walk_tween.tween_property($Visual, "rotation_degrees", 0.0, _step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_is_animating_to_idle = true
