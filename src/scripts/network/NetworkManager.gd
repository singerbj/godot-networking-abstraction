extends Node

var _network = NetworkedMultiplayerENet.new()
var _port = 6969
var _connected = false

var client_required_functions = [
	"_on_connection_failed",
	"_on_connection_succeeded",
	"_on_confirm_connection_internal",
	"_on_state_update_internal",
	"_on_message_received_from_server"
]

var server_required_functions = [
	"_on_peer_disconnected_internal",
	"_on_peer_disconnected_internal",
	"_on_input_reported_internal",
	"_on_message_received_from_client"
]

func verify_required_functions(functions : Array, error_message : String):
	for f in client_required_functions:
		if !has_method(f):
			push_error(error_message % f)
			get_tree().quit()

####################################################
### Client functionality ###########################
####################################################

func connect_to_server(ip_address : String):
	verify_required_functions(client_required_functions, "This game instance cannot be a client - function %s not implemented")
			
	print("Starting client - connecting to %s" % ip_address)
	if ip_address != null:
		_connect_to_server(ip_address)
	else:
		push_error("IP Address not specified")
	
func _connect_to_server(ip_address):
	print("Connecting to server... (with ip: " + ip_address + ")")
	
	get_tree().connect("connection_failed", self, "_on_connection_failed_internal")
	get_tree().connect("connected_to_server", self, "_on_connection_succeeded_internal")
	
	var err = _network.create_client(ip_address, _port, 0, 0)
	print(err)
	get_tree().set_network_peer(_network)
	
func _on_connection_failed_internal():
	_connected = false
	push_error("Failed to connect to server")
	
func _on_connection_succeeded_internal():	
	_connected = true
	print("Connected Successfully")
	
func _report_input(input_id : int, input : Dictionary) -> void: # TODO: create a class to represent input
	if _connected:
		rpc_id(1, "_on_input_reported_internal", input_id, input)
	else:
		print("Not connected so not reporting input")
		
remote func _on_state_update_internal(timestamp, state):
	pass
#	TODO: call implemented method here or something
#	get_node("../Client/PlayersHandler").push_players_update(timestamp, other_players)

remote func _on_confirm_connection_internal(connect_info):
	get_node("../Client/Player").set_up(connect_info["player"])

func _send_generic_message(msg: String, mode: String) -> void:
	rpc_id(1, "_on_message_received_from_client_internal", msg, mode)

remote func _on_message_received_from_server_internal(msg : String, usr : String, chat_mode : String = "normal", color_msg = '#ffffff', color_usr = '#ffffff') -> void:
	print("got msg from server ", msg)



####################################################
### Server functionality ###########################
####################################################

func start_server(port : int, max_players : int = NetworkConfig.DEFAULT_MAXIMUM_PLAYERS):
	verify_required_functions(server_required_functions, "This game instance cannot be a server - function %s not implemented")
			
	_network.create_server(port, max_players)
	var args = Array(OS.get_cmdline_args())
	for arg in args:
		var formatted_arg_array = arg.split("=")
		print(formatted_arg_array)
		if formatted_arg_array.size() == 2 && formatted_arg_array[0] == "-bind-ip":
			var bind_ip = formatted_arg_array[1]
			_network.set_bind_ip(bind_ip)
			print("Using command line specified bind ip: " + bind_ip)
			
		
		
	get_tree().set_network_peer(_network)
	print("Server started")
	
	_network.connect("peer_connected", self, "_on_peer_connected_internal")
	_network.connect("peer_disconnected", self, "_on_peer_disconnected_internal")
	
	
func _on_peer_connected_internal(player_id):
	var new_connect_info = {}
	new_connect_info["player"] = $PlayerManager.set_up_new_player(player_id)
	rpc_id(player_id, "_on_confirm_connection_internal", new_connect_info)
	
	
func _on_peer_disconnected_internal(player_id):
	$PlayerManager.remove_player(player_id)
	
func _send_state():
	pass
	#loop through players and send state

remote func _on_input_reported_internal(input_id : int, input : Dictionary):
	var player_id = get_tree().get_rpc_sender_id()
	input["input_id"] = input_id
	input["rec_time"] = OS.get_system_time_msecs()
#	ServerData.input_buffer[player_id].append(input) # TODO: create server input buffer manager

remote func _on_message_received_from_client_internal(msg : String, mode: String) -> void:
#	TODO: Use the mode here for chat channels
	_send_message(msg, "", mode)
		
func _send_message(msg : String, player_name : String, chat_mode : String = "normal", color_msg = '#ffffff', color_usr = '#ffffff') -> void:
	rpc_id(0, "_on_message_received_from_server_internal", msg, player_name, chat_mode, color_msg, color_usr)
