## Поточні характеристики гравця, ауровий скіл та глобальні модифікатори ворогів.
## Autoload — доступний як PlayerStats з будь-якого скрипта.
extends Node

# ── Характеристики гравця ─────────────────────────────────────
var base_damage: float      = 10.0
var fire_rate_delay: float  = 0.5
var pierce_count: int       = 0
var attack_range: float     = 300.0
var move_speed: float       = 200.0
var max_burnout: float      = 100.0

# ── Аура Гумової Качечки ──────────────────────────────────────
var aura_range: float     = 120.0
var aura_slowdown: float  = 0.7
var aura_dps: float       = 5.0

# ── Глобальні модифікатори ворогів ────────────────────────────
var enemy_hp_mult: float    = 1.0
var enemy_speed_mult: float = 1.0
var spawn_delay_mult: float = 1.0

# ── Система досвіду ───────────────────────────────────────────
const MAX_XP: float = 100.0
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

	aura_range    = RubberDuckConfig.AURA_RANGE
	aura_slowdown = RubberDuckConfig.AURA_SLOWDOWN
	aura_dps      = RubberDuckConfig.AURA_DPS

	enemy_hp_mult    = 1.0
	enemy_speed_mult = 1.0
	spawn_delay_mult = 1.0

	current_xp    = 0.0
	current_level = 0

func add_xp(amount: float) -> void:
	current_xp += amount
	if current_xp >= MAX_XP:
		current_xp -= MAX_XP
		current_level += 1
		level_up.emit()
	xp_changed.emit(current_xp, MAX_XP)
