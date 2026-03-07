extends Node2D

signal wave_started(wave_name: String)

const MARGIN := 50.0

var _enemy_scenes: Array[PackedScene] = [
	preload("res://scenes/enemy_default.tscn"), # TYPE_NORMAL
	preload("res://scenes/enemy_fast.tscn"),    # TYPE_FAST
	preload("res://scenes/enemy_tank.tscn"),    # TYPE_TANK
	preload("res://scenes/enemy_turret.tscn"),  # TYPE_TURRET
	preload("res://scenes/enemy_heal.tscn")     # TYPE_COFFEE
]
var _offset: Vector2

# Стан хвиль
var _current_wave: int = 0
var _wave_timer: float = 0.0
var _spawn_timer: float = 0.0
var _spawn_delay_min: float = 1.5
var _spawn_delay_max: float = 2.5
var _is_announcing: bool = false
var _announce_timer: float = 0.0
var _game_active: bool = false

# Хвиля 5 — прискорення
var _escalate_timer: float = 0.0

func _ready() -> void:
	_offset = GameConfig.get_arena_offset()

## Викликається main.gd після натискання "Старт"
func start_game() -> void:
	_announce_wave(0)

func _announce_wave(wave_index: int) -> void:
	_current_wave = wave_index
	_is_announcing = true
	_announce_timer = 1.0
	_game_active = false
	wave_started.emit(GameConfig.WAVE_CONFIG[wave_index].name)
	AudioManager.play_next_wave_begin()

func _process(delta: float) -> void:
	if _is_announcing:
		_announce_timer -= delta
		if _announce_timer <= 0.0:
			_is_announcing = false
			_start_wave()
		return

	if not _game_active:
		return

	var wave_cfg: Dictionary = GameConfig.WAVE_CONFIG[_current_wave]

	if wave_cfg.duration > 0.0:
		# Скінченна хвиля — рахуємо таймер
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			var next := _current_wave + 1
			if next < GameConfig.WAVE_CONFIG.size():
				_announce_wave(next)
			return
	else:
		# Хвиля 5 — кожні 30 сек прискорюємо спавн
		_escalate_timer -= delta
		if _escalate_timer <= 0.0:
			_escalate_timer = wave_cfg.escalate_interval
			var hardcap: float = wave_cfg.spawn_delay_hardcap
			var amount: float  = wave_cfg.escalate_amount
			_spawn_delay_min = max(hardcap, _spawn_delay_min - amount)
			_spawn_delay_max = max(hardcap, _spawn_delay_max - amount)

	# Спавнимо ворогів
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		var amount_to_spawn := randi_range(2, 3)
		for i in amount_to_spawn:
			_spawn_enemy()
		_spawn_timer = randf_range(_spawn_delay_min, _spawn_delay_max) * PlayerStats.spawn_delay_mult

func _start_wave() -> void:
	_game_active = true
	var wave_cfg: Dictionary = GameConfig.WAVE_CONFIG[_current_wave]
	_wave_timer      = wave_cfg.duration
	_spawn_delay_min = wave_cfg.spawn_delay_min
	_spawn_delay_max = wave_cfg.spawn_delay_max
	
	if _current_wave == 0:
		_spawn_timer = 0.0
	else:
		_spawn_timer = randf_range(_spawn_delay_min, _spawn_delay_max) * PlayerStats.spawn_delay_mult

	if wave_cfg.duration < 0.0:
		_escalate_timer = wave_cfg.escalate_interval

func _spawn_enemy() -> void:
	var type: int = _pick_enemy_type()
	var enemy: Enemy = _enemy_scenes[type].instantiate() as Enemy

	# Налаштовуємо до add_child, щоб не було flash дефолтного вигляду
	enemy.setup(type)

	var aw: float = GameConfig.ARENA_WIDTH
	var ah: float = GameConfig.ARENA_HEIGHT
	var side: int = randi() % 4
	var pos := Vector2.ZERO
	match side:
		0: pos = Vector2(randf_range(_offset.x, _offset.x + aw), _offset.y - MARGIN)
		1: pos = Vector2(randf_range(_offset.x, _offset.x + aw), _offset.y + ah + MARGIN)
		2: pos = Vector2(_offset.x - MARGIN,          randf_range(_offset.y, _offset.y + ah))
		3: pos = Vector2(_offset.x + aw + MARGIN,     randf_range(_offset.y, _offset.y + ah))

	get_parent().add_child(enemy)
	enemy.global_position = pos

## Зважений рандомний вибір типу ворога за вагами поточної хвилі
func _pick_enemy_type() -> int:
	var weights: Array = GameConfig.WAVE_CONFIG[_current_wave].weights
	var total: int = 0
	for w in weights:
		total += int(w)
	var roll: int = randi() % total
	var cumulative: int = 0
	for i in weights.size():
		cumulative += int(weights[i])
		if roll < cumulative:
			return i
	return 0
