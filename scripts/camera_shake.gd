class_name CameraShake
extends Camera2D

@export var shake_enabled: bool = true

var _noise = FastNoiseLite.new()
var _noise_y: float = 0
var _shake_strength: float = 0.0
var _shake_decay: float = 5.0
var _base_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	_base_offset = offset
	add_to_group("camera_shake")
	_noise.seed = randi()
	_noise.frequency = 0.5

func shake_micro(direction: Vector2) -> void:
	if not shake_enabled: return
	# Micro shake uses direct kick + small noise
	_shake_strength = 5.0
	_shake_decay = 15.0 # Fast decay
	# Immediate kick offset
	offset = _base_offset - direction.normalized() * 5.0

func shake_hard() -> void:
	if not shake_enabled: return
	_shake_strength = 20.0
	_shake_decay = 3.0 # Slower decay

func shake_light() -> void:
	if not shake_enabled: return
	_shake_strength = 8.0
	_shake_decay = 10.0

func _process(delta: float) -> void:
	if _shake_strength > 0.1:
		_shake_strength = lerp(_shake_strength, 0.0, _shake_decay * delta)
		_noise_y += delta * 1000.0
		var shake_offset = Vector2(
			_noise.get_noise_2d(1, _noise_y) * _shake_strength,
			_noise.get_noise_2d(100, _noise_y) * _shake_strength
		)
		offset = _base_offset + shake_offset
	else:
		offset = _base_offset
