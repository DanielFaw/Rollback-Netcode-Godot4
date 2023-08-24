extends Node2D

const bomb = preload("res://bomb.tscn")

func _ready():
	"""
	SyncManager.scene_spawned.connect(scene_spawned)
	SyncManager.scene_despawned.connect(scene_despawned)
	"""
	pass

func _get_local_input() -> Dictionary:
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input := {}
	if input_vector != Vector2.ZERO:
		input["input_vector"] = input_vector
	if Input.is_action_just_pressed("ui_accept"):
		input["drop_bomb"] = true
	return input

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	input.erase("drop_bomb")
	return input

func _network_process(input: Dictionary) -> void:
	position += input.get("input_vector", Vector2.ZERO) * 8
	if input.get("drop_bomb", false):
		SyncManager.spawn("Bomb", get_parent(), bomb, {position = global_position})
	pass
"""
func scene_spawned(name, spawned_node, scene, data):
	if name == "Bomb":
		spawned_node.exploded.connect(on_bomb_exploded) 
	pass

func scene_despawned(name, despawned_node):
	if name == "Bomb":
		despawned_node.exploded.disconnect(on_bomb_exploded)
	pass

func on_bomb_exploded():
	print("Boom!")
	pass
"""

func _save_state() -> Dictionary:
	return{
		position = position
	}

func _load_state(state: Dictionary) -> void:
	position = state["position"]
