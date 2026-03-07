## Поточні характеристики гравця, ауровий скіл та глобальні модифікатори ворогів.
## Autoload — доступний як PlayerStats з будь-якого скрипта.
extends Node

# ── Характеристики гравця ─────────────────────────────────────
var base_damage: float      = 10.0
var fire_rate_delay: float  = 0.8
var pierce_count: int       = 0
var attack_range: float     = 300.0
var move_speed: float       = 200.0
var max_burnout: float      = 100.0
var has_second_monitor: bool = false
var backend_blame_dps: float = 0.0
var bullet_speed_mult: float = 1.0
var weapon_spread: float    = 0.0

# ── Аура Гумової Качечки ──────────────────────────────────────
var aura_range: float     = 120.0
var aura_slowdown: float  = 0.7
var aura_dps: float       = 5.0

# ── Глобальні модифікатори ворогів ────────────────────────────
var enemy_hp_mult: float    = 1.0
var enemy_speed_mult: float = 1.0
var spawn_delay_mult: float = 1.0
var enemy_damage_mult: float= 1.0
var xp_requirement_mult: float = 1.0

# ── Система досвіду ───────────────────────────────────────────
var BASE_MAX_XP: float = 100.0
var current_xp: float = 0.0
var current_level: int = 0

signal xp_changed(current: float, maximum: float)
signal level_up

func _ready() -> void:
	reset()

## Скидає всі стати до базових значень (викликається на старті/перезапуску)
func reset() -> void:
	base_damage     = GameConfig.BULLET_DAMAGE
	fire_rate_delay = GameConfig.PLAYER_SHOOT_COOLDOWN
	pierce_count    = 0
	attack_range    = GameConfig.PLAYER_SHOOT_RADIUS
	move_speed      = GameConfig.PLAYER_SPEED
	max_burnout     = GameConfig.PLAYER_MAX_BURNOUT
	has_second_monitor = false
	backend_blame_dps = 0.0
	bullet_speed_mult = 1.0
	weapon_spread   = 0.0

	aura_range    = RubberDuckConfig.AURA_RANGE
	aura_slowdown = RubberDuckConfig.AURA_SLOWDOWN
	aura_dps      = RubberDuckConfig.AURA_DPS

	enemy_hp_mult    = 1.0
	enemy_speed_mult = 1.0
	spawn_delay_mult = 1.0
	enemy_damage_mult= 1.0
	xp_requirement_mult = 1.0

	current_xp    = 0.0
	current_level = 0

func add_xp(amount: float) -> void:
	current_xp += amount
	var required_xp := (BASE_MAX_XP + current_level * 25.0) * xp_requirement_mult
	while current_xp >= required_xp:
		current_xp -= required_xp
		current_level += 1
		required_xp = (BASE_MAX_XP + current_level * 25.0) * xp_requirement_mult
		level_up.emit()
	xp_changed.emit(current_xp, required_xp)
