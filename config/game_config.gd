## Конфіг гри — міняй числа тут, зберігай, перезапускай
extends Node

# VIEWPORT (має співпадати з Project Settings)
const VIEWPORT_WIDTH  := 1024.0
const VIEWPORT_HEIGHT := 768.0

# АРЕНА
const ARENA_WIDTH  := 100.0
const ARENA_HEIGHT := 600.0

# ГРАВЕЦЬ
const PLAYER_SPEED          := 200.0
const PLAYER_HALF_SIZE      := 15.0
const PLAYER_SHOOT_COOLDOWN := 0.5
const PLAYER_SHOOT_RADIUS   := 300.0  # пікселів, 0 = необмежено

# ВИГОРАННЯ
const PLAYER_MAX_BURNOUT := 100.0

# КУЛІ
const BULLET_SPEED    := 450.0
const BULLET_LIFETIME := 3.0
const BULLET_DAMAGE   := 1

# ВОРОГИ
const ENEMY_SPEED           := 80.0
const ENEMY_HEALTH          := 3
const ENEMY_BURNOUT_DAMAGE  := 8.0
const ENEMY_DAMAGE_INTERVAL := 1.0
const ENEMY_DAMAGE_RANGE    := 35.0

# СПАВНЕР
const SPAWN_INTERVAL := 2.0

func get_arena_offset() -> Vector2:
	return Vector2((VIEWPORT_WIDTH - ARENA_WIDTH) / 2.0, (VIEWPORT_HEIGHT - ARENA_HEIGHT) / 2.0)
