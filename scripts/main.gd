extends Node2D

@onready var _arena_floor: Polygon2D = $ArenaFloor
@onready var _burnout_label: Label = $UI/BurnoutLabel
@onready var _burnout_bar: ProgressBar = $UI/BurnoutBar
@onready var _game_over_panel: Panel = $UI/GameOverPanel
@onready var _start_panel: Panel     = $UI/StartPanel
@onready var _start_button: Button   = $UI/StartPanel/MarginContainer/VBoxContainer/StartButton
@onready var _pause_button: Button   = $UI/TopBar/PauseButton
@onready var _restart_button: Button = $UI/TopBar/RestartButton
@onready var _go_restart: Button     = $UI/GameOverPanel/GOVBox/GORestartButton

var _game_over := false

func _ready() -> void:
	_setup_arena()

	var player = $Player
	player.burnout_changed.connect(_on_burnout_changed)
	player.player_died.connect(_on_player_died)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.95, 0.3, 0.05)
	_burnout_bar.add_theme_stylebox_override("fill", fill_style)

	_burnout_bar.min_value = 0.0
	_burnout_bar.max_value = 1.0
	_burnout_bar.value = 0.0
	_game_over_panel.visible = false

	# Skill slots UI
	$UI/SkillBar/PassiveSlot.setup(player.passive_skill, "Пасивний")
	$UI/SkillBar/ActiveSlot1.setup(player.active_skill_1, "X")
	$UI/SkillBar/ActiveSlot2.setup(player.active_skill_2, "C")

	_start_button.pressed.connect(_on_start_pressed)
	_pause_button.pressed.connect(_on_pause_pressed)
	_restart_button.pressed.connect(_on_restart)
	_go_restart.pressed.connect(_on_restart)
	_start_panel.visible = true
	get_tree().paused = true

func _on_start_pressed() -> void:
	_start_panel.visible = false
	get_tree().paused = false
	_pause_button.visible = true
	_restart_button.visible = true

func _on_pause_pressed() -> void:
	get_tree().paused = !get_tree().paused
	_pause_button.text = "▶" if get_tree().paused else "⏸"

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _setup_arena() -> void:
	var offset := GameConfig.get_arena_offset()
	var w := GameConfig.ARENA_WIDTH
	var h := GameConfig.ARENA_HEIGHT

	_arena_floor.polygon = PackedVector2Array([
		Vector2(offset.x,     offset.y),
		Vector2(offset.x + w, offset.y),
		Vector2(offset.x + w, offset.y + h),
		Vector2(offset.x,     offset.y + h),
	])

	$Player.position = offset + Vector2(w / 2.0, h / 2.0)

func _on_burnout_changed(current: float, maximum: float) -> void:
	var pct := current / maximum
	_burnout_bar.value = pct
	_burnout_label.text = "Вигорання: %d%%" % int(pct * 100)

func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	get_tree().paused = true
	_game_over_panel.visible = true
	_pause_button.visible = false
	_restart_button.visible = false
