extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

const input_path_mapping := {
	"/root/Main/ServerPlayer" : 1,
	"/root/Main/ClientPlayer" : 2,
}

enum HeaderFlags{
	HAS_INPUT_VECTOR = 0x01,
	DROP_BOMB = 0x02,
	TELEPORT = 0x04
}

var input_path_mapping_reverse := {}

func _init():
	for key in input_path_mapping:
		input_path_mapping_reverse[input_path_mapping[key]] = key
	pass

func serialize_input(all_input: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(16)
	
	buffer.put_u32(all_input['$'])
	buffer.put_u8(all_input.size() - 1)
	
	for path in all_input:
		if path == '$':
			continue
		buffer.put_u8(input_path_mapping[path])
		
		var header := 0
		
		var input = all_input[path]
		if input.has('input_vector'):
			header |= HeaderFlags.HAS_INPUT_VECTOR
		if input.get('drop_bomb', false):
			header |= HeaderFlags.DROP_BOMB
		if input.get('teleport', false):
			header |= HeaderFlags.TELEPORT
		
		buffer.put_u8(header)
		
		if input.has('input_vector'):
			var input_vector : Vector2 = input['input_vector']
			buffer.put_float(input_vector.x)
			buffer.put_float(input_vector.y)
	
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)
	
	var all_input := {}
	
	all_input['$'] = buffer.get_u32()
	
	var input_count = buffer.get_u8()
	if input_count == 0:
		return all_input
	
	var path = input_path_mapping_reverse[buffer.get_u8()]
	var input := {}
	
	var header = buffer.get_u8()
	if header & HeaderFlags.HAS_INPUT_VECTOR:
		input['input_vector'] = Vector2(buffer.get_float(), buffer.get_float())
	if header & HeaderFlags.DROP_BOMB:
		input['drop_bomb'] = true
	if header & HeaderFlags.TELEPORT:
		input['teleport'] = true
	
	all_input[path] = input
	return all_input




