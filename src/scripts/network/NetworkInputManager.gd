extends Node


class_name NetworkInputManager

var _input_buffers = {}
var _buffer_max_size

func _init(buffer_max_size : int):
	_buffer_max_size = buffer_max_size
	
func add_input(id : int, input : NetworkInput) -> void:
	if !id in _input_buffers:
		_input_buffers[id] = []
	
	_input_buffers[id].append(input)
	
	if _input_buffers[id].size() > _buffer_max_size:
		_input_buffers[id].pop_front()
	
func get_ids() -> Array:
	return _input_buffers.keys()
	
func get_input_buffer(id : int) -> Array:
	var input_buffer_copy = _input_buffers[id]
	_input_buffers[id] = []
	return input_buffer_copy
	
func get_and_clear_input_buffer(id : int) -> Array:
	var input_buffer_copy = _input_buffers[id]
	_input_buffers[id] = []
	return input_buffer_copy
