extends PassiveSkillBase

var _player: Node2D = null

func apply(player: Node) -> void:
	_player     = player
	skill_name  = RubberDuckConfig.SKILL_NAME
	description = RubberDuckConfig.DESCRIPTION

func _process(delta: float) -> void:
	if _player == null:
		return
	var range_sq: float = PlayerStats.aura_range * PlayerStats.aura_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion():
			continue
		var dist_sq: float = _player.global_position.distance_squared_to(enemy.global_position)
		if dist_sq <= range_sq:
			enemy._aura_slow_mult = PlayerStats.aura_slowdown
			enemy.take_damage(PlayerStats.aura_dps * delta)
