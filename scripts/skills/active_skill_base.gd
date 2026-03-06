class_name ActiveSkillBase
extends Node

var skill_name: String = ""
var description: String = ""
var icon: Texture2D = null
var cooldown_duration: float = 1.0

var _remaining_cooldown: float = 0.0

func _process(delta: float) -> void:
	_remaining_cooldown = maxf(0.0, _remaining_cooldown - delta)

func can_activate() -> bool:
	return _remaining_cooldown <= 0.0

func activate(player: Node) -> void:
	if not can_activate():
		return
	_remaining_cooldown = cooldown_duration
	_do_activate(player)

## Перевизнач цей метод в дочірньому класі
func _do_activate(_player: Node) -> void:
	pass

## Повертає 0.0..1.0 — скільки кулдауну залишилось
func get_cooldown_pct() -> float:
	if cooldown_duration <= 0.0:
		return 0.0
	return _remaining_cooldown / cooldown_duration
