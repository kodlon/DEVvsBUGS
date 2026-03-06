class_name HealthPickup
extends Area2D

var _heal_amount: float = 35.0

func setup(amount: float) -> void:
	_heal_amount = amount

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := Timer.new()
	timer.wait_time = 12.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.reduce_burnout(_heal_amount)
		queue_free()
