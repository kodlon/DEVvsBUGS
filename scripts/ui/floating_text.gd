class_name FloatingText
extends Label

var _amount: float = 0.0
var _is_crit: bool = false
var _duration: float = 0.4

func setup(amount: float, is_crit: bool = false, source: String = "") -> void:
    _amount = amount
    _is_crit = is_crit
    text = str(int(amount))
    
    if _is_crit:
        add_theme_font_size_override("font_size", 30)
        add_theme_color_override("font_color", Color.RED)
        z_index = 100
    elif source == "aura":
        add_theme_font_size_override("font_size", 18)
        add_theme_color_override("font_color", Color(0.6, 0.2, 1.0)) # Purple
        z_index = 90
    else:
        add_theme_font_size_override("font_size", 20)
        add_theme_color_override("font_color", Color.WHITE)
        z_index = 95
        
    add_theme_constant_override("outline_size", 4)
    add_theme_color_override("font_outline_color", Color.BLACK)
    
    _start_tween()

func _start_tween() -> void:
    var duration = 2.0
    var tween = create_tween()
    tween.set_parallel(true)
    
    # Fly straight up, reduced speed (-25 pixels over 2s matches half speed feeling)
    var target_pos = position + Vector2(0, -25.0)
    tween.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    
    # Fade out
    tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    
    tween.set_parallel(false)
    tween.tween_callback(queue_free)
