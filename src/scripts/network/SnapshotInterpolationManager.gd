extends Node

class_name SnapshotInterpolationManager

var vault 

var _name : String
var _network_config
var _interpolation_buffer
var _auto_correct_time_offset
var _whitespace_regex : RegEx
var _time_offset = -1

var server_time = 0

func _init(name : String, network_config : NetworkConfig, auto_correct_time_offset : bool):
	_name = name
	_network_config = network_config
	vault = Vault.new(_network_config)
	_interpolation_buffer = (1000 / Engine.iterations_per_second) * _network_config.DEFAULT_INTERPOLATION_BUFFER_MULTIPLIER
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
	
func create_new_id() -> String:
	return Util.gen_unique_string(6)

func create_snapshot(state: Array, last_processed_input_ids : Dictionary):
	return Snapshot.new(create_new_id(), now(), state, last_processed_input_ids)

func add_snapshot(snapshot : Snapshot):
#	print("[%s] Adding snapshot" % _name)
	var now = now()

	if _time_offset == -1:
		_time_offset = now - snapshot.time
		
	if _auto_correct_time_offset:
		var time_offset = now - snapshot.time
		var time_difference = abs(_time_offset - time_offset)
		if(time_difference > _network_config.DEFAULT_MAX_TIME_OFFSET_MS):
			_time_offset = time_offset
			
	vault.add(snapshot)

func interpolate(snapshot_a : Snapshot, snapshot_b : Snapshot, time_or_percentage : int, parameters : Array) -> InterpolatedSnapshot:
	var snapshot_array = [snapshot_a, snapshot_b]
	snapshot_array.sort_custom(Util, "sort_snapshots")
	
	var newer : Snapshot = snapshot_array[0]
	var older : Snapshot = snapshot_array[1]

	var t0 : int = newer.time
	var t1 : int = older.time
	
	var zero_percent = time_or_percentage - t1
	var hundred_percent = t0 - t1
	var p_percent
	if hundred_percent == 0:
		print("Divide by zero in interpolate")
		p_percent = 0
	else:
		p_percent = time_or_percentage if time_or_percentage <= 1 else zero_percent / hundred_percent

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

		for j in len(parameters):
			var param = parameters[j]
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

func get_server_time() -> int:
	return now() - _time_offset - _interpolation_buffer

func calculate_interpolation(parameters : Array) -> InterpolatedSnapshot:
	var server_time : int = get_server_time()
	
	var snapshots = vault.get_surrounding_snapshots(server_time)
	if snapshots[0] == null || snapshots[1] == null: return null
	
	return interpolate(snapshots[0], snapshots[1], server_time, parameters)
	
