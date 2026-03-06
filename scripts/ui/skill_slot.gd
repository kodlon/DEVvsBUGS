extends Control

@onready var _icon: TextureRect     = $VBox/SlotPanel/Icon
@onready var _cd_overlay: ColorRect = $VBox/SlotPanel/CooldownOverlay
@onready var _empty_label: Label    = $VBox/SlotPanel/EmptyLabel
@onready var _key_label: Label      = $VBox/KeyLabel
@onready var _slot_panel: Panel      = $VBox/SlotPanel
@onready var _tooltip: Panel        = $Tooltip
@onready var _tooltip_text: RichTextLabel = $Tooltip/Margin/TooltipText

var _skill = null

func _ready() -> void:
	_tooltip.visible = false

func setup(skill, key_hint: String) -> void:
	_skill = skill
	_key_label.text = key_hint

	if skill == null:
		_empty_label.text = "?"
		_tooltip_text.text = "Порожньо"
		return

	if skill.icon != null:
		_icon.texture = skill.icon
		_empty_label.visible = false
	else:
		_empty_label.text = skill.skill_name.substr(0, 2) if skill.skill_name.length() > 0 else "?"

	_tooltip_text.text = "[b]%s[/b]\n\n%s" % [skill.skill_name, skill.description]

func _process(_delta: float) -> void:
	# Тултіп — перевіряємо позицію миші напряму (надійніше ніж сигнали)
	var mouse := get_global_mouse_position()
	var slot_rect := _slot_panel.get_global_rect()
	_tooltip.visible = not get_tree().paused and slot_rect.has_point(mouse) and _skill != null

	# Кулдаун оверлей
	if _skill == null or not _skill.has_method("get_cooldown_pct"):
		_cd_overlay.visible = false
		return
	var pct: float = _skill.get_cooldown_pct()
	_cd_overlay.visible = pct > 0.0
	_cd_overlay.color = Color(0.0, 0.0, 0.0, 0.75 * pct)
