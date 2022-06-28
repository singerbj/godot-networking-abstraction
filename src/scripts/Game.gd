extends NetworkManager

signal timer_end

var local_peer_id : int
var players = {}
var Player = preload("res://src/scenes/Player.tscn")

func _ready():
	var args = Array(OS.get_cmdline_args())
#	if "server" in args:
	self.start_server(false, 4)
#	if "client" in args:
	self.connect_to_server("127.0.0.1")
	
func _physics_process(delta):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

########################################################
### Required Server Implementation Functions ###########
########################################################

func _on_server_creation_error(error):
	pass
	
func _on_peer_connected(peer_id : int):
	if !_local_peer_is_server():
		var peer_player = Player.instance()
		players[peer_id] = peer_player
		add_child(peer_player)
	
func _on_peer_disconnected(peer_id):
	players[peer_id].queue_free()
	players.erase(peer_id)
	
func _on_input_reported(input : NetworkInput):
	pass
	
func _process_inputs(delta : int, peer_id : int, inputs : Array):
	for input in inputs:
		if peer_id in players:
			players[peer_id].move(delta, input)

func _on_request_entities() -> Array:
	var entities = []
	for peer_id in players.keys():
		var entity = PlayerEntity.new(peer_id, players[peer_id].transform)
		entities.append(entity)
	return entities
	
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
	players[local_peer_id] = local_player
	add_child(local_player)
	
func _on_snapshot_recieved(state : Snapshot):
	pass
	
func _on_update_local_entity(delta : float, entity : PlayerEntity):
	print(entity)
	
func _on_input_data_requested() -> Dictionary:
	var data = {}
	if Input.is_action_pressed("m_forward"):
		data["m_forward"] = true
	if Input.is_action_pressed("m_backward"):
		data["m_backward"] = true
	if Input.is_action_pressed("m_left"):
		data["m_left"] = true
	if Input.is_action_pressed("m_right"):
		data["m_right"] = true
	return data
	
func	 _on_interpolation_parameters_requested() -> Array:
	return ["transform.origin.x", "transform.origin.z"]
	
func _on_client_side_predict(delta : float, input : NetworkInput):
#	if local_peer_id in players:
#		players[local_peer_id].move(delta, input)
	pass
	
func _on_message_received_from_server():
	pass
