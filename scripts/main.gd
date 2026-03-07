extends Node2D

@onready var _arena_floor: Polygon2D     = $ArenaFloor
@onready var _burnout_label: Label       = $UI/BurnoutLabel
@onready var _burnout_bar: ProgressBar   = $UI/BurnoutBar
@onready var _game_over_panel: Panel     = $UI/GameOverPanel
@onready var _start_panel: Panel         = $UI/StartPanel
@onready var _start_button: Button       = $UI/StartPanel/MarginContainer/VBoxContainer/StartButton
@onready var _pause_button: Button       = $UI/TopBar/PauseButton
@onready var _restart_button: Button     = $UI/TopBar/RestartButton
@onready var _go_restart: Button         = $UI/GameOverPanel/GOVBox/GORestartButton
@onready var _go_vbox: VBoxContainer     = $UI/GameOverPanel/GOVBox

var _game_over := false

# Рахунок
var _score: int = 0
var _score_label: Label = null
var _go_score_label: Label = null

# Хвильовий оверлей
var _wave_overlay_bg: ColorRect = null
var _wave_label: Label = null

# XP
var _xp_bar: ProgressBar = null
var _xp_label: Label = null

func _ready() -> void:
	PlayerStats.reset()   # скидаємо при кожному перезапуску сцени
	add_to_group("score_tracker")
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

	# Хвильовий спавнер
	$Spawner.wave_started.connect(_on_wave_started)

	_setup_score_ui()
	_setup_wave_overlay()
	_setup_xp_ui()

func _process(delta: float) -> void:
	if _burnout_bar.value > 0.8:
		# Pulsate red
		var s = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
		_burnout_bar.modulate = Color(1.0, s, s)
	else:
		_burnout_bar.modulate = Color.WHITE

# ── Score UI ────────────────────────────────────────────────

func _setup_score_ui() -> void:
	# Лейбл рахунку по центру зверху (in-game)
	_score_label = Label.new()
	_score_label.anchor_left   = 0.0
	_score_label.anchor_right  = 1.0
	_score_label.anchor_top    = 0.0
	_score_label.anchor_bottom = 0.0
	_score_label.offset_top    = 10.0
	_score_label.offset_bottom = 42.0
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	_score_label.add_theme_constant_override("outline_size", 3)
	_score_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_score_label.text = "Пофіксовано багів: 0"
	$UI.add_child(_score_label)

	# Лейбл рахунку на екрані Game Over
	_go_score_label = Label.new()
	_go_score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_go_score_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_go_score_label.add_theme_font_size_override("font_size", 20)
	_go_score_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	_go_score_label.text = "Ваша пофікшена кількість багів: 0"
	_go_vbox.add_child(_go_score_label)
	_go_vbox.move_child(_go_score_label, 2)  # після GOTitle і GOSubtitle

func add_score(amount: int) -> void:
	_score += amount
	_score_label.text = "Пофіксовано багів: %d" % _score

# ── Wave overlay ─────────────────────────────────────────────

func _setup_wave_overlay() -> void:
	_wave_overlay_bg = ColorRect.new()
	_wave_overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wave_overlay_bg.color = Color(0.0, 0.0, 0.0, 0.65)
	_wave_overlay_bg.visible = false
	$UI.add_child(_wave_overlay_bg)

	_wave_label = Label.new()
	_wave_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_wave_label.add_theme_font_size_override("font_size", 64)
	_wave_label.add_theme_color_override("font_color", Color(1.0, 0.05, 0.05))
	_wave_label.add_theme_constant_override("outline_size", 5)
	_wave_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_wave_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_wave_label.visible = false
	$UI.add_child(_wave_label)

func _on_wave_started(wave_name: String) -> void:
	_wave_label.text = wave_name
	_wave_label.modulate.a = 1.0
	_wave_overlay_bg.modulate.a = 1.0
	_wave_label.visible = true
	_wave_overlay_bg.visible = true

	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_wave_label,      "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(_wave_overlay_bg, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		_wave_label.visible = false
		_wave_overlay_bg.visible = false
	)

# ── Кнопки ───────────────────────────────────────────────────

func _on_start_pressed() -> void:
	_start_panel.visible = false
	get_tree().paused = false
	_pause_button.visible = true
	_restart_button.visible = true
	$Spawner.start_game()

func _on_pause_pressed() -> void:
	get_tree().paused = !get_tree().paused
	_pause_button.text = "▶" if get_tree().paused else "⏸"

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# ── Арена ────────────────────────────────────────────────────

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

# ── Колбеки ──────────────────────────────────────────────────

func _on_burnout_changed(current: float, maximum: float) -> void:
	var pct := current / maximum
	var is_damage = pct > _burnout_bar.value
	
	_burnout_bar.value = pct
	_burnout_label.text = "Вигорання: %d%%" % int(pct * 100)
	
	if is_damage and !_game_over:
		var tween = create_tween()
		var init_x = 10.0 # From _burnout_bar.offset_left in UI
		tween.tween_property(_burnout_bar, "position:x", init_x - 10.0, 0.05)
		tween.tween_property(_burnout_bar, "position:x", init_x + 10.0, 0.05)
		tween.tween_property(_burnout_bar, "position:x", init_x - 10.0, 0.05)
		tween.tween_property(_burnout_bar, "position:x", init_x, 0.05)

func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	_go_score_label.text = "Ваша пофікшена кількість багів: %d" % _score
	get_tree().paused = true
	_game_over_panel.visible = true
	_pause_button.visible = false
	_restart_button.visible = false

# ── XP бар ───────────────────────────────────────────────────

func _setup_xp_ui() -> void:
	# Золота шкала XP внизу екрану
	_xp_bar = ProgressBar.new()
	_xp_bar.set_anchor(SIDE_LEFT,   0.0)
	_xp_bar.set_anchor(SIDE_RIGHT,  1.0)
	_xp_bar.set_anchor(SIDE_TOP,    1.0)
	_xp_bar.set_anchor(SIDE_BOTTOM, 1.0)
	_xp_bar.offset_top    = -26.0
	_xp_bar.offset_bottom =  0.0
	_xp_bar.min_value     = 0.0
	_xp_bar.max_value     = PlayerStats.BASE_MAX_XP * PlayerStats.xp_requirement_mult
	_xp_bar.value         = 0.0
	_xp_bar.show_percentage = false

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(1.0, 0.82, 0.1)
	_xp_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.12, 0.12, 0.85)
	_xp_bar.add_theme_stylebox_override("background", bg_style)

	$UI.add_child(_xp_bar)

	# Підпис поверх шкали
	_xp_label = Label.new()
	_xp_label.set_anchor(SIDE_LEFT,   0.0)
	_xp_label.set_anchor(SIDE_RIGHT,  1.0)
	_xp_label.set_anchor(SIDE_TOP,    1.0)
	_xp_label.set_anchor(SIDE_BOTTOM, 1.0)
	_xp_label.offset_top    = -26.0
	_xp_label.offset_bottom =  0.0
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_xp_label.add_theme_font_size_override("font_size", 13)
	_xp_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	_xp_label.add_theme_constant_override("outline_size", 2)
	_xp_label.add_theme_color_override("font_outline_color", Color(1.0, 0.9, 0.4, 0.8))
	_xp_label.text = "Рівень 0  ·  XP: 0 / 100"
	$UI.add_child(_xp_label)

	PlayerStats.xp_changed.connect(_on_xp_changed)
	PlayerStats.level_up.connect(_on_level_up)

func _on_xp_changed(current: float, maximum: float) -> void:
	_xp_bar.value = current
	_xp_label.text = "Рівень %d  ·  XP: %d / %d" % [
		PlayerStats.current_level, int(current), int(maximum)
	]

func _on_level_up() -> void:
	call_deferred("_show_level_up_ui")

func _show_level_up_ui() -> void:
	# Уникаємо появи двох вікон одночасно
	for child in $UI.get_children():
		if child is LevelUpUI:
			return
	var ui := LevelUpUI.new()
	$UI.add_child(ui)
	ui.setup()
	get_tree().paused = true
