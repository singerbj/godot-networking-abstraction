extends NetworkManager

var local_peer_id : int
var players = {}
var Player = preload("res://src/scenes/Player.tscn")
var mouse_motion : Vector2 = Vector2(0, 0)
var reconciliations : int = 0

const RECONCILIATION_TOLERANCE : float = 3.0
const RECONCILIATION_FACTOR : float = 0.125

func _ready():
	var args = Array(OS.get_cmdline_args())
	var start_server = "server" in args
	var start_client = "client" in args
	if !start_server && !start_client:
		start_server = false
		start_client = true

	if start_server:
		OS.set_window_title("Server")
		self.start_server()
	if start_client:
		OS.set_window_title("Client")
		self.connect_to_server(NetworkUtil.get_cmd_line_ipaddress())
	if start_server && start_client:
		OS.set_window_title("Server and Client")
	
	if start_client:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _physics_process(delta):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
		
	if Input.is_action_just_pressed("camera_switch"):
		if $Camera.current:
			players[local_peer_id].set_camera_active()
		else:
			$Camera.make_current()
		
func _process(delta):
	$Label.text = "[FPS: %s] [Reconciliations: %s]" % [str(Engine.get_frames_per_second()), reconciliations]
	
	if local_peer_id != null && local_peer_id in players:
		players[local_peer_id].rotate_player_with_input(mouse_motion)
		mouse_motion = Vector2(0, 0)
		
func _input(event) -> void:
	if event is InputEventMouseMotion:
		mouse_motion += event.relative
		
func _unhandled_input(event):
	if Input.is_action_just_pressed("change_mouse_mode"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

########################################################
### Required Server Implementation Functions ###########
########################################################

func _on_server_creation_error(error):
	pass
	
func _on_peer_connected(peer_id : int):
	if peer_id != local_peer_id:
		var peer_player = Player.instance()
		players[peer_id] = peer_player
		add_child(peer_player)
	
func _on_peer_disconnected(peer_id):
	players[peer_id].queue_free()
	players.erase(peer_id)
	
func _process_inputs(delta : float, peer_id : int, inputs : Array):
	for input in inputs:
		if (peer_id in players) && ((!_local_peer_is_server()) || (_local_peer_is_server() && peer_id != local_peer_id)):
			if "rotation" in input["data"] && "head_nod_angle" in input["data"]:
				players[peer_id].rotate_player_with_values(input["data"]["rotation"], input["data"]["head_nod_angle"])
			players[peer_id].move(input, delta)
	
########################################################
### Required Client Implementation Functions ###########
########################################################	
	
func _on_connection_failed():
	pass
	
func _on_connection_succeeded():
	pass
	
func _on_confirm_connection(peer_id : int):
	local_peer_id = peer_id
	var local_player = Player.instance()
	local_player.is_local_player = true
	players[local_peer_id] = local_player
	add_child(local_player)
	local_player.set_camera_active()
	
func _on_snapshot_recieved(state : Snapshot):
	pass
	
func _on_update_local_entity(delta : float, entity : PlayerEntity):
	if local_peer_id != null:
		if !entity.id in players:
			var peer_player = Player.instance()
			players[entity.id] = peer_player
			add_child(peer_player)
		players[entity.id].update_from_server(entity.transform, entity.rotation, entity.head_nod_angle)
	
func _on_input_data_requested() -> Dictionary:
	var data = {}
	
	if local_peer_id != null && local_peer_id in players:
		data["rotation"] = players[local_peer_id].rotation_degrees.y
		data["head_nod_angle"] = players[local_peer_id].head_nod_angle
		
	if Input.is_action_pressed("m_forward"):
		data["m_forward"] = true
	if Input.is_action_pressed("m_backward"):
		data["m_backward"] = true
	if Input.is_action_pressed("m_left"):
		data["m_left"] = true
	if Input.is_action_pressed("m_right"):
		data["m_right"] = true
	if Input.is_action_pressed("jump"):
		data["jump"] = true
		
	return data
	
func	 _on_interpolation_parameters_requested() -> Array:
	return [
		"transform.origin.x", "transform.origin.y", "transform.origin.z",
		"rotation.x", "rotation.y", "rotation.z",
		"head_nod_angle"
	]
	
func _on_client_side_predict(delta : float, input : NetworkInput):
	if local_peer_id in players:
		players[local_peer_id].move(input, delta)

func _on_server_reconcile(delta : float, latest_server_snapshot : Snapshot, closest_client_snaphot : InterpolatedSnapshot, input_buffer : Array):
	var server_entity
	for entity in latest_server_snapshot.state:
		if entity.id == local_peer_id:
			server_entity = entity
			break

	var client_entity
	for entity in closest_client_snaphot.state:
		if entity.id == local_peer_id:
			client_entity = entity
			break
			
	if server_entity != null && client_entity != null:
		# calculate the offset between server and client
		var offset_x = abs(players[local_peer_id].transform.origin.x - server_entity.transform.origin.x)
		var offset_y = abs(players[local_peer_id].transform.origin.y - server_entity.transform.origin.y)
		var offset_z = abs(players[local_peer_id].transform.origin.z - server_entity.transform.origin.z)

		if offset_x > RECONCILIATION_TOLERANCE || offset_y > RECONCILIATION_TOLERANCE || offset_z > RECONCILIATION_TOLERANCE:
			reconciliations += 1
			players[local_peer_id].transform.origin =  players[local_peer_id].transform.origin.linear_interpolate(server_entity.transform.origin, RECONCILIATION_FACTOR)
	
func _on_message_received_from_server():
	pass
	
########################################################
### Required Both Implementation Functions ###########
########################################################	
	
func _on_request_entity_classes() -> Array:
	return [PlayerEntity]
	
func _on_request_entities() -> Array:
	var entities = []
	for peer_id in players.keys():
		var entity = PlayerEntity.new({ 
			"id": peer_id, 
			"transform": players[peer_id].transform, 
			"velocity": players[peer_id].velocity, 
			"rotation": players[peer_id].rotation,
			"head_nod_angle": players[peer_id].head_nod_angle 
		})
		entities.append(entity)
	return entities
