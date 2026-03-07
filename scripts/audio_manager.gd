extends Node

const VOLUME_HALF := -6.02 # ~ half linear volume

var bgm_player: AudioStreamPlayer
var shoot_player: AudioStreamPlayer
var take_damage_player: AudioStreamPlayer
var next_wave_player: AudioStreamPlayer
var level_up_player: AudioStreamPlayer
var enemy_hit_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep playing when paused
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = preload("res://sounds/BackgroundMusic.wav")
	bgm_player.volume_db = -12.0 # ~25% linear volume
	add_child(bgm_player)
	bgm_player.finished.connect(bgm_player.play)
	bgm_player.play()
	
	shoot_player = AudioStreamPlayer.new()
	shoot_player.stream = preload("res://sounds/Shoot.ogg")
	add_child(shoot_player)
	
	take_damage_player = AudioStreamPlayer.new()
	take_damage_player.stream = preload("res://sounds/ReceivedDamage.ogg")
	add_child(take_damage_player)
	
	next_wave_player = AudioStreamPlayer.new()
	next_wave_player.stream = preload("res://sounds/NextWaveBegin.ogg")
	next_wave_player.volume_db = VOLUME_HALF
	add_child(next_wave_player)
	
	level_up_player = AudioStreamPlayer.new()
	level_up_player.stream = preload("res://sounds/LevelUp.ogg")
	add_child(level_up_player)
	
	enemy_hit_player = AudioStreamPlayer.new()
	enemy_hit_player.stream = preload("res://sounds/EnemyHit.ogg")
	# Reduce enemy hit slightly as it can be spammy
	enemy_hit_player.volume_db = -2.0 
	add_child(enemy_hit_player)

func play_shoot() -> void:
	shoot_player.play()

func play_received_damage() -> void:
	take_damage_player.play()

func play_next_wave_begin() -> void:
	next_wave_player.play()

func play_level_up() -> void:
	level_up_player.play()

func play_enemy_hit() -> void:
	enemy_hit_player.play()
