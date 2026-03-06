extends CharacterBody2D

var _player: Node2D = null
var _health: int = GameConfig.ENEMY_HEALTH
var _damage_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return

	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * GameConfig.ENEMY_SPEED
	move_and_slide()

	_damage_timer -= delta
	if _damage_timer <= 0.0:
		var dist := global_position.distance_to(_player.global_position)
		if dist < GameConfig.ENEMY_DAMAGE_RANGE:
			_player.take_burnout(GameConfig.ENEMY_BURNOUT_DAMAGE)
			_damage_timer = GameConfig.ENEMY_DAMAGE_INTERVAL

func take_damage(amount: int) -> void:
	_health -= amount
	if _health <= 0:
		queue_free()
