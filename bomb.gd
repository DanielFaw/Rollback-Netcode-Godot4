extends Node2D

const explosion = preload("res://explosion.tscn")

@export var explosion_timer : NetworkTimer

"""
signal exploded()
"""

func _ready():
	explosion_timer.timeout.connect(explosion_timer_timeout)
	pass
"""
func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
	data['player_path'] = data['player'].get_path()
	data.erase('player')
	return data
"""
func _network_spawn(data: Dictionary) -> void:
	global_position = data['position']
	explosion_timer.start()

func explosion_timer_timeout():
	SyncManager.spawn("Explosion", get_parent(), explosion, {
		position = global_position
	})
	SyncManager.despawn(self)
	pass
