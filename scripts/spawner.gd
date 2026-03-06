extends Node2D

const MARGIN := 50.0

var _enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var _timer: float = 0.0
var _offset: Vector2

func _ready() -> void:
	_offset = GameConfig.get_arena_offset()

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_spawn_enemy()
		_timer = GameConfig.SPAWN_INTERVAL

func _spawn_enemy() -> void:
	var enemy = _enemy_scene.instantiate()
	get_parent().add_child(enemy)

	var aw := GameConfig.ARENA_WIDTH
	var ah := GameConfig.ARENA_HEIGHT
	var side := randi() % 4
	var pos := Vector2.ZERO
	match side:
		0: pos = Vector2(randf_range(_offset.x, _offset.x + aw), _offset.y - MARGIN)
		1: pos = Vector2(randf_range(_offset.x, _offset.x + aw), _offset.y + ah + MARGIN)
		2: pos = Vector2(_offset.x - MARGIN, randf_range(_offset.y, _offset.y + ah))
		3: pos = Vector2(_offset.x + aw + MARGIN, randf_range(_offset.y, _offset.y + ah))

	enemy.global_position = pos
