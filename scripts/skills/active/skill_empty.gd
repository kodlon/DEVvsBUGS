extends ActiveSkillBase

func _ready() -> void:
	skill_name        = "???"
	description       = "Скоро буде..."
	cooldown_duration = 0.0

func can_activate() -> bool:
	return false  # порожній слот — не можна використати
