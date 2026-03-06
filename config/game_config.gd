## Конфіг гри — міняй числа тут, зберігай, перезапускай
extends Node

# VIEWPORT (має співпадати з Project Settings)
const VIEWPORT_WIDTH  := 1024.0
const VIEWPORT_HEIGHT := 768.0

# АРЕНА
const ARENA_WIDTH  := 1000.0
const ARENA_HEIGHT := 744.0

# ГРАВЕЦЬ
const PLAYER_SPEED          := 200.0
const PLAYER_HALF_SIZE      := 15.0
const PLAYER_SHOOT_COOLDOWN := 0.5
const PLAYER_SHOOT_RADIUS   := 300.0  # пікселів, 0 = необмежено

# ВИГОРАННЯ
const PLAYER_MAX_BURNOUT := 100.0

# КУЛІ ГРАВЦЯ (базова шкода = 10 за постріл)
const BULLET_SPEED    := 450.0
const BULLET_LIFETIME := 3.0
const BULLET_DAMAGE   := 10.0

# ВОРОЖІ ДОТИКИ
const ENEMY_DAMAGE_INTERVAL := 1.0
const ENEMY_DAMAGE_RANGE    := 35.0

# ============================================================
# КОНФІГИ ВОРОГІВ
# Ключі: 0=NORMAL, 1=FAST, 2=TANK, 3=TURRET, 4=COFFEE
# Швидкості: "ігрові одиниці" * 80 = пікс/с
# ============================================================
const ENEMY_CONFIG := {
	0: {  # Junior's Typo — звичайний баг
		"hp_min": 25.0, "hp_max": 35.0,
		"speed_min": 160.0, "speed_max": 200.0,
		"burnout_min": 5.0, "burnout_max": 7.0,
		"color": Color(0.85, 0.15, 0.15),
		"base_scale": 1.0,
		"score_value": 10,   # масовка, 3-4 постріли
	},
	1: {  # Hotfix — швидкий баг
		"hp_min": 10.0, "hp_max": 15.0,
		"speed_min": 304.0, "speed_max": 384.0,
		"burnout_min": 2.0, "burnout_max": 4.0,
		"color": Color(0.95, 0.45, 0.0),
		"base_scale": 0.6,
		"score_value": 15,   # складно влучити, але вмирає швидко
	},
	2: {  # Legacy Code — танк-баг
		"hp_min": 120.0, "hp_max": 160.0,
		"speed_min": 64.0, "speed_max": 104.0,
		"burnout_min": 20.0, "burnout_max": 25.0,
		"color": Color(0.15, 0.45, 0.1),
		"base_scale": 1.9,
		"score_value": 50,   # 12-16 пострілів + критична шкода
	},
	3: {  # Toxic Reviewer — жук-турелька
		"hp_min": 40.0, "hp_max": 55.0,
		"speed_min": 120.0, "speed_max": 160.0,
		"burnout_min": 0.0, "burnout_max": 0.0,
		"color": Color(0.55, 0.05, 0.75),
		"base_scale": 1.2,
		"stop_range": 180.0,
		"fire_delay_min": 2.5,
		"fire_delay_max": 4.0,
		"acid_speed_min": 240.0,
		"acid_speed_max": 320.0,
		"acid_damage_min": 10.0,
		"acid_damage_max": 15.0,
		"score_value": 30,   # небезпечний здалеку, 4-6 пострілів
	},
	4: {  # Coffee Scarab — жук-ящик
		"hp_min": 60.0, "hp_max": 80.0,
		"speed_min": 200.0, "speed_max": 280.0,
		"burnout_min": 0.0, "burnout_max": 0.0,
		"color": Color(0.95, 0.8, 0.1),
		"base_scale": 0.85,
		"flee_range": 200.0,
		"wander_change_time": 2.0,
		"heal_min": 30.0,
		"heal_max": 40.0,
		"score_value": 20,   # жертвуєш хілкою заради балів
	},
}

# ============================================================
# КОНФІГ ХВИЛЬ
# weights: [NORMAL, FAST, TANK, TURRET, COFFEE] (відносні ваги)
# duration: -1.0 = безкінечна хвиля
# ============================================================
const WAVE_CONFIG := [
	{  # Хвиля 1: "Таск на 5 хвилиночок"
		"name": "Таск на 5 хвилиночок",
		"duration": 60.0,
		"spawn_delay_min": 1.5,
		"spawn_delay_max": 2.5,
		"weights": [85, 10, 0, 0, 5],
	},
	{  # Хвиля 2: "Мерж-конфлікт у мейні"
		"name": "Мерж-конфлікт у мейні",
		"duration": 60.0,
		"spawn_delay_min": 1.0,
		"spawn_delay_max": 1.8,
		"weights": [50, 35, 10, 0, 5],
	},
	{  # Хвиля 3: "Правки від замовника"
		"name": "Правки від замовника\n(П'ятниця, 17:50)",
		"duration": 75.0,
		"spawn_delay_min": 0.7,
		"spawn_delay_max": 1.2,
		"weights": [40, 20, 15, 20, 5],
	},
	{  # Хвиля 4: "ПРОД ВПАВ!"
		"name": "ПРОД ВПАВ!\nУсі на кол!",
		"duration": 90.0,
		"spawn_delay_min": 0.4,
		"spawn_delay_max": 0.8,
		"weights": [30, 30, 20, 15, 5],
	},
	{  # Хвиля 5: "РЕЛІЗНИЙ КРАНЧ" — безкінечна
		"name": "РЕЛІЗНИЙ КРАНЧ:\nДедлайн був вчора!!!",
		"duration": -1.0,
		"spawn_delay_min": 0.3,
		"spawn_delay_max": 0.5,
		"escalate_interval": 30.0,
		"escalate_amount": 0.05,
		"spawn_delay_hardcap": 0.1,
		"weights": [25, 25, 10, 20, 5],
	},
]

# ============================================================
# ДОСВІД З ВОРОГІВ
# Ключі: 0=NORMAL, 1=FAST, 2=TANK, 3=TURRET, 4=COFFEE
# ============================================================
const XP_PER_ENEMY := {
	0: 10.0,
	1: 5.0,
	2: 50.0,
	3: 20.0,
	4: 15.0,
}

func get_arena_offset() -> Vector2:
	return Vector2((VIEWPORT_WIDTH - ARENA_WIDTH) / 2.0, (VIEWPORT_HEIGHT - ARENA_HEIGHT) / 2.0)
