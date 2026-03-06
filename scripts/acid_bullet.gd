class_name AcidBullet
extends Area2D

var direction := Vector2.RIGHT
var _speed: float = 280.0
var _damage: float = 12.0

func setup(dir: Vector2, speed: float, damage: float) -> void:
	direction = dir
	_speed = speed
	_damage = damage

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _process(delta: float) -> void:
	position += direction * _speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_burnout(_damage)
		queue_free()
