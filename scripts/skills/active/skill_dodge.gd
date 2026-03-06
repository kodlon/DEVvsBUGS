extends ActiveSkillBase

func _ready() -> void:
	skill_name        = DodgeConfig.SKILL_NAME
	description       = DodgeConfig.DESCRIPTION
	cooldown_duration = DodgeConfig.COOLDOWN

func _do_activate(player: Node) -> void:
	player.start_dash()
