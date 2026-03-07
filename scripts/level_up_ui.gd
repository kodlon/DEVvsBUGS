## UI вибору прокачки при левел-апі.
## Додається до $UI в main.gd при спрацюванні PlayerStats.level_up.
class_name LevelUpUI
extends Control

# ── Рідкісність ───────────────────────────────────────────────
const RARITY_COLORS := {
	"junior": Color(0.82, 0.82, 0.82),
	"middle": Color(0.25, 0.45, 0.95),
	"senior": Color(0.60, 0.10, 0.90),
}
const RARITY_LABELS := {
	"junior": "*  JUNIOR",
	"middle": "**  MIDDLE",
	"senior": "***  SENIOR",
}
const RARITY_TITLES := {
	"junior": [
		"Quick Fix™", "TODO: Refactor Later", "Ctrl+Z Undo",
		"Junior's Hotfix", "Copy-Paste Solution", "It Works On My Machine",
	],
	"middle": [
		"Stack Overflow Approved", "Mid-Sprint Refactor",
		"Code Review: 2 Comments", "Middle's Pull Request", "Design Pattern Applied",
	],
	"senior": [
		"Architecture Decision", "Senior's Wisdom",
		"10x Developer Mode", "Technical Debt Repaid", "SOLID Principle Enforced",
	],
}

# ── Статистики гравця ─────────────────────────────────────────
const PLAYER_STAT_NAMES: Array = [
	"base_damage", "fire_rate_delay", "move_speed", "pierce_count",
	"aura_range", "aura_dps", "attack_range", "max_burnout",
	"backend_blame_dps", "has_second_monitor"
]
const PLAYER_BUFF_VALUES := {
	"base_damage":     {"junior": 0.10, "middle": 0.20, "senior": 0.40},
	"fire_rate_delay": {"junior": 0.05, "middle": 0.10, "senior": 0.25},
	"move_speed":      {"junior": 0.05, "middle": 0.10, "senior": 0.20},
	"pierce_count":    {"junior": 1.0,  "middle": 2.0,  "senior": 3.0 },
	"aura_range":      {"junior": 0.10, "middle": 0.20, "senior": 0.35},
	"aura_dps":        {"junior": 0.10, "middle": 0.20, "senior": 0.35},
	"attack_range":    {"junior": 0.10, "middle": 0.20, "senior": 0.30},
	"max_burnout":     {"junior": 0.05, "middle": 0.10, "senior": 0.20},
	"backend_blame_dps": {"junior": 1.0, "middle": 2.0, "senior": 3.0},
	"has_second_monitor": {"junior": 1.0, "middle": 1.0, "senior": 1.0},
}

# ── Статистики ворогів ────────────────────────────────────────
const ENEMY_STAT_NAMES: Array = [
	"enemy_hp_mult", "enemy_speed_mult", "spawn_delay_mult",
	"bullet_speed_mult", "enemy_damage_mult", "xp_requirement_mult", "weapon_spread"
]
const ENEMY_BUFF_VALUES := {
	"enemy_hp_mult":    {"junior": 0.0, "middle": 0.10, "senior": 0.20},
	"enemy_speed_mult": {"junior": 0.0, "middle": 0.05, "senior": 0.12},
	"spawn_delay_mult": {"junior": 0.0, "middle": 0.07, "senior": 0.15},
	"bullet_speed_mult": {"junior": 0.0, "middle": 0.02, "senior": 0.05},
	"enemy_damage_mult": {"junior": 0.0, "middle": 0.01, "senior": 0.03},
	"xp_requirement_mult": {"junior": 0.0, "middle": 0.05, "senior": 0.10},
	"weapon_spread": {"junior": 0.0, "middle": 1.0, "senior": 5.0}, # in degrees
}

var _overlay: ColorRect
var _cards: Array = []
var _dismissing: bool = false

# ── Константи розкладки ───────────────────────────────────────
const _TITLE_H := 52.0
const _CARD_H  := 290.0
const _GAP     := 16.0

func setup() -> void:
	# Абсолютний розмір — не залежить від того, чи вже прорахований layout батька
	position     = Vector2.ZERO
	size         = Vector2(GameConfig.VIEWPORT_WIDTH, GameConfig.VIEWPORT_HEIGHT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	AudioManager.play_level_up()
	_create_overlay()
	_create_title()
	_create_cards()

# ── Оверлей затемнення ────────────────────────────────────────

func _create_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.position    = Vector2.ZERO
	_overlay.size        = Vector2(GameConfig.VIEWPORT_WIDTH, GameConfig.VIEWPORT_HEIGHT)
	_overlay.color       = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 0.7, 0.2)

# ── Заголовок ─────────────────────────────────────────────────

func _create_title() -> void:
	var lbl := Label.new()
	# Абсолютна позиція: над картками
	lbl.position = Vector2(0.0, _block_start_y())
	lbl.size     = Vector2(GameConfig.VIEWPORT_WIDTH, _TITLE_H)
	lbl.text     = "LEVEL UP!  Вибери Trade-off"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

# ── Картки ────────────────────────────────────────────────────

## Y верхньої межі всього блоку (заголовок + картки), центровано по вертикалі
func _block_start_y() -> float:
	return (GameConfig.VIEWPORT_HEIGHT - (_TITLE_H + _GAP + _CARD_H)) / 2.0

## Y верхньої межі HBox з картками
func _cards_start_y() -> float:
	return _block_start_y() + _TITLE_H + _GAP

func _create_cards() -> void:
	var card_data_arr: Array = _generate_three_cards()

	# Контейнер — абсолютна позиція по центру viewport
	var card_w     := 200.0
	var card_gap   := 20.0
	var total_w    := card_w * 3 + card_gap * 2   # 640px

	var hbox := HBoxContainer.new()
	hbox.position = Vector2(
		(GameConfig.VIEWPORT_WIDTH - total_w) / 2.0,  # 192px від лівого краю
		_cards_start_y()
	)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", int(card_gap))
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hbox)

	for i in 3:
		var card := _build_card(card_data_arr[i])
		card.pivot_offset = card.custom_minimum_size / 2.0
		card.scale        = Vector2.ZERO
		hbox.add_child(card)
		_cards.append(card)

		# Поява з ефектом overshoot
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.15 + i * 0.09)
		tw.tween_property(card, "scale", Vector2.ONE, 0.3)

func _build_card(data: Dictionary) -> Control:
	var rarity: String = data.rarity

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200.0, 290.0)
	panel.mouse_filter        = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color                   = RARITY_COLORS[rarity]
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color        = Color(1.0, 1.0, 1.0, 0.7)
	style.content_margin_left   = 10.0
	style.content_margin_right  = 10.0
	style.content_margin_top    = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Рідкісність
	var rarity_lbl := Label.new()
	rarity_lbl.text = RARITY_LABELS[rarity]
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_lbl.add_theme_font_size_override("font_size", 13)
	rarity_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(rarity_lbl)

	# Заголовок — жарт
	var title_lbl := Label.new()
	title_lbl.text = data.title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_lbl)

	vbox.add_child(HSeparator.new())

	# Позитивний ефект (зелений)
	var plus_lbl := Label.new()
	plus_lbl.text = data.player_text
	plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plus_lbl.add_theme_font_size_override("font_size", 14)
	if data.player_value <= 0.0:
		plus_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	else:
		plus_lbl.add_theme_color_override("font_color", Color(0.15, 1.0, 0.35))
	plus_lbl.add_theme_constant_override("outline_size", 2)
	plus_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	vbox.add_child(plus_lbl)

	vbox.add_child(HSeparator.new())

	# Негативний ефект (червоний)
	var minus_lbl := Label.new()
	minus_lbl.text = data.enemy_text
	minus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	minus_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	minus_lbl.add_theme_font_size_override("font_size", 14)
	if data.enemy_value <= 0.0:
		minus_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	else:
		minus_lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.15))
	minus_lbl.add_theme_constant_override("outline_size", 2)
	minus_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	vbox.add_child(minus_lbl)

	# Підказка
	var hint_lbl := Label.new()
	hint_lbl.text = "[ натисни щоб вибрати ]"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 11)
	hint_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	vbox.add_child(hint_lbl)

	# Hover та Click
	panel.mouse_entered.connect(func() -> void: _on_hover(panel, true))
	panel.mouse_exited.connect(func()  -> void: _on_hover(panel, false))
	panel.gui_input.connect(func(ev: InputEvent) -> void: _on_input(ev, data, panel))

	return panel

# ── Hover / Click ─────────────────────────────────────────────

func _on_hover(card: Control, is_hover: bool) -> void:
	if _dismissing:
		return
	var target := Vector2(1.08, 1.08) if is_hover else Vector2.ONE
	var tw := create_tween()
	tw.tween_property(card, "scale", target, 0.12)

func _on_input(event: InputEvent, data: Dictionary, card: Control) -> void:
	if _dismissing:
		return
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_select_card(data)

# ── Застосування карти ────────────────────────────────────────

func _select_card(data: Dictionary) -> void:
	_dismissing = true

	_apply_card(data)

	# Анімація зникнення карток
	for card in _cards:
		var tw := create_tween()
		tw.tween_property(card, "scale", Vector2.ZERO, 0.2)

	# Знімаємо оверлей і знищуємо UI
	var tw := create_tween()
	tw.tween_property(_overlay, "color:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		get_tree().paused = false
		queue_free()
	)

func _apply_card(data: Dictionary) -> void:
	var p_val: float = data.player_value
	match data.player_stat:
		"base_damage":     PlayerStats.base_damage     *= (1.0 + p_val)
		"fire_rate_delay": PlayerStats.fire_rate_delay *= (1.0 - p_val)
		"move_speed":      PlayerStats.move_speed      *= (1.0 + p_val)
		"pierce_count":    PlayerStats.pierce_count    += int(p_val)
		"aura_range":      PlayerStats.aura_range      *= (1.0 + p_val)
		"aura_dps":        PlayerStats.aura_dps        *= (1.0 + p_val)
		"attack_range":    PlayerStats.attack_range    *= (1.0 + p_val)
		"max_burnout":     PlayerStats.max_burnout     *= (1.0 + p_val)
		"backend_blame_dps": 
			if PlayerStats.backend_blame_dps == 0.0:
				PlayerStats.backend_blame_dps = p_val
			else:
				PlayerStats.backend_blame_dps *= (1.0 + p_val / 10.0) # зростає потроху після першого взяття
		"has_second_monitor": PlayerStats.has_second_monitor = true

	var e_val: float = data.enemy_value
	match data.enemy_stat:
		"enemy_hp_mult":    PlayerStats.enemy_hp_mult    *= (1.0 + e_val)
		"enemy_speed_mult": PlayerStats.enemy_speed_mult *= (1.0 + e_val)
		"spawn_delay_mult": PlayerStats.spawn_delay_mult *= (1.0 - e_val)
		"bullet_speed_mult": PlayerStats.bullet_speed_mult *= (1.0 - e_val)
		"enemy_damage_mult": PlayerStats.enemy_damage_mult *= (1.0 + e_val)
		"xp_requirement_mult": PlayerStats.xp_requirement_mult *= (1.0 + e_val)
		"weapon_spread": PlayerStats.weapon_spread += e_val # additive

# ── Генератор карток ──────────────────────────────────────────

func _generate_three_cards() -> Array:
	var cards: Array = []
	var available_stats: Array = PLAYER_STAT_NAMES.duplicate()

	# Remove "has_second_monitor" if the player already has it
	if PlayerStats.has_second_monitor:
		available_stats.erase("has_second_monitor")
	elif PlayerStats.current_level < 3:
		# Не випадає на перших рівнях взагалі, щоб не "одразу"
		available_stats.erase("has_second_monitor")

	for _i in 3:
		var rarity := _pick_rarity()

		var idx_p: int
		var p_stat: String
		
		idx_p = randi() % available_stats.size()
		p_stat = available_stats[idx_p]
		available_stats.remove_at(idx_p)

		# Рандомний стат ворогів
		var e_stat: String = ENEMY_STAT_NAMES[randi() % ENEMY_STAT_NAMES.size()]

		var p_val: float = PLAYER_BUFF_VALUES[p_stat][rarity]
		var e_val: float = ENEMY_BUFF_VALUES[e_stat][rarity]

		cards.append({
			"rarity":      rarity,
			"player_stat": p_stat,
			"player_value": p_val,
			"player_text": _player_text(p_stat, p_val),
			"enemy_stat":  e_stat,
			"enemy_value": e_val,
			"enemy_text":  _enemy_text(e_stat, e_val),
			"title":       _pick_title(rarity),
		})

	return cards

func _pick_rarity() -> String:
	var roll: int = randi() % 100
	if roll < 60:    return "junior"
	elif roll < 90:  return "middle"
	else:            return "senior"

func _pick_title(rarity: String) -> String:
	var t: Array = RARITY_TITLES[rarity]
	return t[randi() % t.size()]

func _player_text(stat: String, value: float) -> String:
	if value <= 0.0 and stat != "has_second_monitor" and stat != "backend_blame_dps":
		return "Без бонусів"
	match stat:
		"base_damage":     return "+%d%% Шкода від пострілу" % int(value * 100)
		"fire_rate_delay": return "-%d%% Затримка стрільби" % int(value * 100)
		"move_speed":      return "+%d%% Швидкість руху" % int(value * 100)
		"pierce_count":    return "+%d Пробиття снаряда" % int(value)
		"aura_range":      return "+%d%% Радіус аури Stepico" % int(value * 100)
		"aura_dps":        return "+%d%% DPS аури Stepico" % int(value * 100)
		"attack_range":    return "+%d%% Радіус прицілювання" % int(value * 100)
		"max_burnout":     return "+%d%% Макс. Вигорання" % int(value * 100)
		"backend_blame_dps": 
			if PlayerStats.backend_blame_dps == 0.0:
				return "Скіл: Спихнути на бекенд (%.1f DMG/s)" % value
			else:
				return "+%d%% Шкоди бекенда" % int(value * 10)
		"has_second_monitor": return "Скіл: +1 Монітор (Подвійний постріл)"
	return "+??"

func _enemy_text(stat: String, value: float) -> String:
	if value <= 0.0:
		return "Без штрафів"
	match stat:
		"enemy_hp_mult":    return "Але баги товстіші на +%d%%!" % int(value * 100)
		"enemy_speed_mult": return "Але баги швидші на +%d%%!" % int(value * 100)
		"spawn_delay_mult": return "Але баги лізуть на %d%% частіше!" % int(value * 100)
		"bullet_speed_mult": return "Але фікси летять повільніше на %d%%!" % int(value * 100)
		"enemy_damage_mult": return "Але П'ятничний деплой (Шкода +%d%%)!" % int(value * 100)
		"xp_requirement_mult": return "Але Мікроменеджмент (XP на левел +%d%%)!" % int(value * 100)
		"weapon_spread": return "Але Спагетті код (Розкид зброї +%d°)!" % int(value)
	return "Але щось стає гіршим!"
