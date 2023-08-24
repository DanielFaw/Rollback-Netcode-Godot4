extends Node2D

const dummy_network_adapter = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")

@export var main_menu : HBoxContainer
@export var connection_panel : Window
@export var host_field : LineEdit
@export var port_field : LineEdit
@export var message_label : Label
@export var server_button : Button
@export var client_button : Button
@export var reset_button : Button
@export var sync_lost_label : Label

@export var online_button : Button
@export var local_button : Button

@export var johnny : NetworkRandomNumberGenerator

const LOG_FILE_DIRECTORY = "user://detailed_logs"
var logging_enabled := true


func _ready():
	server_button.pressed.connect(server_pressed)
	client_button.pressed.connect(client_pressed)
	reset_button.pressed.connect(reset_pressed)
	online_button.pressed.connect(online_pressed)
	local_button.pressed.connect(local_pressed)
	
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	multiplayer.server_disconnected.connect(on_server_disconnected)
	
	SyncManager.sync_started.connect(sync_started)
	SyncManager.sync_stopped.connect(sync_stopped)
	SyncManager.sync_lost.connect(sync_lost)
	SyncManager.sync_regained.connect(sync_regained)
	SyncManager.sync_error.connect(sync_error)
	pass


func server_pressed():
	johnny.randomize()
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port_field.text.to_int(), 1)
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	main_menu.visible = false
	message_label.text = "Listening..."
	pass

func client_pressed():
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(host_field.text, port_field.text.to_int())
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	main_menu.visible = false
	message_label.text = "Connecting..."
	pass

func reset_pressed():
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	get_tree().reload_current_scene()
	pass

func online_pressed():
	connection_panel.popup_centered()
	SyncManager.reset_network_adaptor()
	
	pass

func local_pressed():
	main_menu.visible = false
	$ClientPlayer.input_prefix = "player2_"
	SyncManager.network_adaptor = dummy_network_adapter.new()
	SyncManager.start()
	pass



func on_peer_connected(peer_id : int):
	message_label.text = "Connected!"
	SyncManager.add_peer(peer_id)
	

	$ServerPlayer.set_multiplayer_authority(1)
	if multiplayer.is_server():
		$ClientPlayer.set_multiplayer_authority(peer_id)
	else:
		$ClientPlayer.set_multiplayer_authority(multiplayer.get_unique_id())
	
	if multiplayer.is_server():
		message_label.text = "Starting..."
		setup_match({mother_seed = johnny.get_seed()})
		setup_match.rpc({mother_seed = johnny.get_seed()})
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()
		pass
	
	pass

@rpc("reliable")
func setup_match(info: Dictionary):
	johnny.set_seed(info["mother_seed"])
	$ClientPlayer.rng.set_seed(johnny.randi())
	$ServerPlayer.rng.set_seed(johnny.randi())
	pass


func on_peer_disconnected(peer_id : int):
	message_label.text = "Disconnected"
	SyncManager.remove_peer(peer_id)
	pass

func on_server_disconnected():
	on_peer_disconnected(1)
	pass

func sync_started():
	message_label.text = "Started!"
	
	if logging_enabled && !SyncReplay.active:
		var dir := DirAccess.open("user://")
		if !dir.dir_exists(LOG_FILE_DIRECTORY):
			dir.make_dir(LOG_FILE_DIRECTORY)
		
		var datetime = Time.get_datetime_dict_from_system()
		var log_file_name = "%04d%02d%02d-%02d%02d%02d-peer-%d.log" % [
			datetime.year,
			datetime.month,
			datetime.day,
			datetime.hour,
			datetime.minute,
			datetime.second,
			multiplayer.get_unique_id()
		]
		
		SyncManager.start_logging(LOG_FILE_DIRECTORY + "/" + log_file_name)
		
	pass

func sync_stopped():
	if logging_enabled:
		SyncManager.stop_logging()
	pass

func sync_lost():
	sync_lost_label.visible = true
	pass

func sync_regained():
	sync_lost_label.visible = false
	pass

func sync_error(msg: String):
	message_label.text = "Fatal sync error: " + msg
	sync_lost_label.visible = false
	var peer := multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()
	pass


func setup_match_for_replay(my_peer_id : int, peer_ids : Array, match_info : Dictionary):
	connection_panel.visible = false
	main_menu.visible = false
	reset_button.visible = false
	pass
