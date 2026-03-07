extends Area2D

var direction := Vector2.RIGHT
var _hits_remaining: int = 1

func _ready() -> void:
	_hits_remaining = 1 + PlayerStats.pierce_count
	body_entered.connect(_on_body_entered)
	var timer := Timer.new()
	timer.wait_time = GameConfig.BULLET_LIFETIME
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _process(delta: float) -> void:
	position += direction * GameConfig.BULLET_SPEED * PlayerStats.bullet_speed_mult * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(PlayerStats.base_damage)
		_hits_remaining -= 1
		if _hits_remaining <= 0:
			queue_free()
