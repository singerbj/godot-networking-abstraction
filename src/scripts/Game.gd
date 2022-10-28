extends NetworkManager

var local_peer_id : int
var players = {}
var Player = preload("res://src/scenes/Player.tscn")
var mouse_motion : Vector2 = Vector2(0, 0)
var reconciliations : int = 0

const RECONCILIATION_TOLERANCE : float = 3.0
const RECONCILIATION_FACTOR : float = 0.125

const WEAPON_DAMAGE : float = 10.0 #TODO: Move this to a weapon manager thingy

func _ready():
	var args = Array(OS.get_cmdline_args())
	var start_server = "server" in args
	var start_client = "client" in args
	if !start_server && !start_client: # TODO: put these in a config file that is in gitignore?
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
	if local_peer_id in players:
		$UI/Label.text = "[FPS: %s] [Reconciliations: %s] [Server Clock: %s] [Player Health: %s]" % [
			str(Engine.get_frames_per_second()), 
			reconciliations, server_snapshot_manager.get_server_time(),
			players[local_peer_id].health
		]
	
	if local_peer_id != null && local_peer_id in players:
		players[local_peer_id].rotate_player_with_input(mouse_motion)
		mouse_motion = Vector2(0, 0)
		
func _input(event) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED && event is InputEventMouseMotion:
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
		peer_player.player_id = peer_id
		players[peer_id] = peer_player
		add_child(peer_player)
	
func _on_peer_disconnected(peer_id):
	if peer_id in players:
		players[peer_id].queue_free()
		players.erase(peer_id)
		
func _before_process_inputs():
	ShotManager.clear_shots()
	
func _process_inputs(delta : float, peer_id : int, inputs : Array):
	for input in inputs:
		if peer_id in players:
			if !_local_peer_is_server() || (_local_peer_is_server() && peer_id != local_peer_id):
				if "rotation" in input["data"] && "head_nod_angle" in input["data"]:
					players[peer_id].rotate_player_with_values(input["data"]["rotation"], input["data"]["head_nod_angle"])
				players[peer_id].move(input, delta)
			
			if "hit" in input["data"]:
				var hit = input["data"]["hit"]
				if hit in players:
					players[hit].take_damage(WEAPON_DAMAGE)
				
				
func _after_process_inputs():
	pass
	
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
	local_player.player_id = local_peer_id
	players[local_peer_id] = local_player
	add_child(local_player)
	local_player.set_camera_active()
	if peer_id == 0:
		local_player.is_bot = true
	
	
func _on_snapshot_recieved(snapshot : Snapshot):
	for entity in snapshot.state.values():
		if entity is ShotEntity:
			if entity.peer_id == local_peer_id && entity.hit:
				$UI.show_hitmarker()
	
func _on_update_local_entity(delta : float, entity : Entity):
	if entity is PlayerEntity:
		if local_peer_id != null:
			if !entity.id in players:				
				_on_peer_connected(entity.id)
			if local_peer_id == entity.id:
				players[entity.id].update_local_player_from_server(entity)
			else:
				players[entity.id].update_peer_player_from_server(entity)
	if entity is ShotEntity:
			if entity.peer_id != local_peer_id:
				ShotManager.fire_client_shot(entity, true)
	
func _on_peer_disconnect_reported(peer_id):
	if peer_id in players:
		players[peer_id].queue_free()
		players.erase(peer_id)
	
func _on_input_data_requested() -> Dictionary:
	var data = {}
	
	if local_peer_id != null && local_peer_id in players:
		data["player_id"] = local_peer_id
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
	if Input.is_action_pressed("shoot"):
		data["shooting"] = true
		var player_camera = players[local_peer_id].get_camera()
		var shooting_origin = player_camera.project_ray_origin(Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2))
		var shooting_normal = player_camera.project_ray_normal(Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2))
		data["shooting_origin"] = shooting_origin
		data["shooting_normal"] = shooting_normal
		$UI/ShootLabel.text = "Shooting!"
#		$UI/ShootDataLabel.text = str(shooting_origin) + "\n" + str(shooting_normal)

		var new_shot = ShotEntity.new({
			"id": "s" + str(ShotManager.get_new_shot_id()),
			"peer_id": local_peer_id, 
			"time": 0, # not relevant for the local simulation of the shot
			"origin": data["shooting_origin"],
			"normal": data["shooting_normal"],
			"hit": -1,
		})
		
		new_shot = ShotManager.fire_client_detection_shot(new_shot, [players[local_peer_id]])
		data["hit"] = new_shot.hit
		if new_shot.hit != -1:
			$UI.show_hitmarker()
	else:
		$UI/ShootLabel.text = ""
	
	return data
		
func _on_client_side_predict(delta : float, input : NetworkInput):
	if local_peer_id in players:
		players[local_peer_id].move(input, delta)

func _on_server_reconcile(delta : float, latest_server_snapshot : Snapshot, closest_client_snaphot : InterpolatedSnapshot, input_buffer : Array):
	var server_entity : Entity
	var client_entity : Entity
	if local_peer_id in latest_server_snapshot.state:
		server_entity = latest_server_snapshot.state[local_peer_id]
	if local_peer_id in closest_client_snaphot.state:
		client_entity = closest_client_snaphot.state[local_peer_id]
			
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
	return [PlayerEntity, ShotEntity]
	
func _on_request_entities() -> Dictionary:
	var entities = {}
	for peer_id in players.keys():
		var player_entity = PlayerEntity.new({ 
			"id": peer_id, 
			"transform": players[peer_id].transform, 
			"velocity": players[peer_id].velocity, 
			"rotation": players[peer_id].rotation,
			"head_nod_angle": players[peer_id].head_nod_angle,
			"health": players[peer_id].health,
		})
		entities[player_entity.id] = player_entity
		
	for shot_entity in ShotManager.get_server_shots():
		entities[shot_entity.id] = shot_entity
		
	return entities
