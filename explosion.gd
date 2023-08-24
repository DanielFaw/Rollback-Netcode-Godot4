extends Node2D

@export var despawn_timer : NetworkTimer
@export var animation_player : NetworkAnimationPlayer
const sound = preload("res://assets/explosion.wav")

func _ready():
	despawn_timer.timeout.connect(despawn_timer_timeout)
	pass

func _network_spawn(data: Dictionary) -> void:
	global_position = data['position']
	despawn_timer.start()
	animation_player.play("Explode")
	SyncManager.play_sound(str(get_path()) + ":explosion", sound)

func despawn_timer_timeout():
	SyncManager.despawn(self)
	pass
