extends Node

class_name SnapshotInterpolation

var vault = Vault.new()

var _interpolation_buffer : int = NetworkConfig.DEFAULT_INTERPOLATION_BUFFER_MS
var _auto_correct_time_offset : bool = NetworkConfig.DEFAULT_AUTO_CORRECT_TIME_OFFSET
var _time_offset : int = -1
var _whitespace_regex : RegEx

var server_time = 0

func _init(server_fps : int, auto_correct_time_offset : bool = NetworkConfig.DEFAULT_AUTO_CORRECT_TIME_OFFSET):
	_interpolation_buffer = (1000 / server_fps) * NetworkConfig.DEFAULT_INTERPOLATION_BUFFER_MULTIPLIER
	_auto_correct_time_offset = auto_correct_time_offset
	_whitespace_regex = RegEx.new()
	_whitespace_regex.compile("\\W+")

func get_interpolation_buffer() -> int:
	return _interpolation_buffer
	
func set_interpolation_buffer(milliseconds : int) -> void:
	_interpolation_buffer = milliseconds

func now() -> int:
	return OS.get_system_time_msecs()

func get_time_offset():
	return _time_offset
	
var _ascii_letters_and_digits = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
func _gen_unique_string(length: int) -> String:
	var result = ""
	for i in range(length):
		result += _ascii_letters_and_digits[randi() % _ascii_letters_and_digits.length()]
	return result
	
func create_new_id() -> String:
	return _gen_unique_string(6)

func create_snapshot(state: Array):
	return Snapshot.new(create_new_id(), now(), state)

func add_snapshot(snapshot : Snapshot):
	var now = now()

	if _time_offset == -1:
		_time_offset = now - snapshot.time
		
	if _auto_correct_time_offset:
		var time_offset = now - snapshot.time
		var time_difference = abs(_time_offset - time_offset)
		if(time_difference > NetworkConfig.DEFAULT_MAX_TIME_OFFSET_MS):
			_time_offset = time_offset

func interpolate(snapshot_a : Snapshot, snapshot_b : Snapshot, time_or_percentage : int, parameters : String) -> InterpolatedSnapshot:
	var sorted = [snapshot_a, snapshot_b].sort_custom(SnapshotSorter, "sort")
	var parameters_trimmed = parameters.strip_edges()
	var params = _whitespace_regex.sub(parameters_trimmed, " ").split(" ")
	
	var newer : Snapshot = sorted[0]
	var older : Snapshot = sorted[1]

	var t0 : int = newer.time
	var t1 : int = older.time
	
	var zero_percent = time_or_percentage - t1
	var hundred_percent = t0 - t1
	var p_percent = time_or_percentage if time_or_percentage <= 1 else zero_percent / hundred_percent

	var server_time = lerp(t1, t0, p_percent)

	var temp_snapshot: Snapshot = newer

	for i in len(newer.state):
		var e1 = newer.state[i]
		var e2 : Entity
		for temp_e in older.state:
			if e1.id == temp_e.id:
				e2 = temp_e
				break
				
		if !e2: return null

		for j in len(params):
			var param = params[j]
			var p0 = e1
			var p1 = e2
			if "." in param:
				var sub_param_array = param.split(".")
				for sub_param in sub_param_array:
					p0 = p0[sub_param]
					p1 = p1[sub_param]
			else:
				p0 = e1[param]
				p1 = e2[param]

			var pn = lerp(p1, p0, p_percent)
			
			var new_state_to_update = temp_snapshot.state[i]
			if "." in param:
				var sub_param_array = param.split(".")
				var temp_attr_ref = new_state_to_update		
				for k in len(sub_param_array): # TODO: good chance this is broken
					var sub_param = sub_param_array[k]
					if k < sub_param_array.size() - 1:
						temp_attr_ref = temp_attr_ref[sub_param]
					else:
						temp_attr_ref[sub_param] = pn
			else:
				new_state_to_update[param] = pn

	var interpolatedSnapshot : InterpolatedSnapshot = InterpolatedSnapshot.new(temp_snapshot.state, p_percent, newer.id, older.id)
	return interpolatedSnapshot

func calculate_interpolation(parameters : String) -> InterpolatedSnapshot:
	var server_time = now() - _time_offset - _interpolation_buffer
	
	var snapshots = vault.get_surrounding_snapshots(server_time)
	if snapshots[0] == null || snapshots[1] == null: return null
	
	return interpolate(snapshots[0],  snapshots[1], server_time, parameters)
