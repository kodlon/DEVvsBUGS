extends Area2D

var direction := Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := Timer.new()
	timer.wait_time = GameConfig.BULLET_LIFETIME
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _process(delta: float) -> void:
	position += direction * GameConfig.BULLET_SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(GameConfig.BULLET_DAMAGE)
		queue_free()
