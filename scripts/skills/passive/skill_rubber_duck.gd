extends PassiveSkillBase

var _player: Node = null
var _timer: float = 0.0

func apply(player: Node) -> void:
	_player       = player
	skill_name    = RubberDuckConfig.SKILL_NAME
	description   = RubberDuckConfig.DESCRIPTION

func _process(delta: float) -> void:
	if _player == null:
		return
	_timer -= delta
	if _timer <= 0.0:
		_player.reduce_burnout(RubberDuckConfig.REGEN_AMOUNT)
		_timer = RubberDuckConfig.INTERVAL
