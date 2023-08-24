extends Node2D

@export var despawn_timer : NetworkTimer
@export var animation_player : NetworkAnimationPlayer

func _ready():
	despawn_timer.timeout.connect(despawn_timer_timeout)
	pass

func _network_spawn(data: Dictionary) -> void:
	global_position = data['position']
	despawn_timer.start()
	animation_player.play("Explode")

func despawn_timer_timeout():
	SyncManager.despawn(self)
	pass
