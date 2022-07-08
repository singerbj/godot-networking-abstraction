extends Node

class_name NetworkManager

var _network : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
var _is_server : bool = false
var _is_client : bool = false
var _client_connected : bool = false
var _server_connected : bool = false
var _local_peer_id : int
var _physics_process_tick : int = 0
var _process_tick : int = 0

var _entity_classes : Dictionary = {}
var interpolation_parameters : Array = []

var _network_config : NetworkConfig = NetworkConfig.new()

var server_input_manager : NetworkInputManager = NetworkInputManager.new(_network_config.DEFAULT_INPUT_BUFFER_MAX_SIZE)
var client_input_manager : NetworkInputManager = NetworkInputManager.new(_network_config.DEFAULT_INPUT_BUFFER_MAX_SIZE)


var server_snapshot_manager : SnapshotInterpolationManager = SnapshotInterpolationManager.new("Server", _network_config, _network_config.DEFAULT_AUTO_CORRECT_TIME_SERVER_OFFSET)
var client_snapshot_manager : SnapshotInterpolationManager = SnapshotInterpolationManager.new("Client", _network_config, _network_config.DEFAULT_AUTO_CORRECT_TIME_CLIENT_OFFSET)

########################################################
### Implementation verification ########################
########################################################

var client_required_functions = [
	"_on_request_entity_classes",
	"_on_connection_failed",
	"_on_connection_succeeded",
	"_on_confirm_connection",
	"_on_snapshot_recieved",
	"_on_message_received_from_server",
	"_on_interpolation_parameters_requested",
	"_on_update_local_entity",
	"_on_input_data_requested",
	"_on_client_side_predict",
	"_on_server_reconcile",
	"_on_request_entities",
]

var server_required_functions = [
	"_on_request_entity_classes",
	"_on_server_creation_error",
	"_on_peer_connected",
	"_on_peer_disconnected",
#	"_on_input_reported",
#	"_on_message_received_from_client",
	"_process_inputs",
	"_on_request_entities",
]

func verify_required_functions(functions : Array, error_message : String):
	for f in functions:
		if !has_method(f):
			push_error(error_message % f)
			get_tree().quit()

########################################################
### Client functionality ###############################
########################################################

func connect_to_server(ip_address : String):
	verify_required_functions(client_required_functions, "This game instance cannot be a client - function %s not implemented")
	
	if _is_client == false:
		_is_client = true
				
		print("Starting client...")
		if _server_connected:
			_on_client_is_server_internal()
		else:
			if ip_address != null:
				_connect_to_server(ip_address)
			else:
				push_error("IP Address not specified")
	else:
		push_error("Cannot start a client if a client is already started.")
	
func _connect_to_server(ip_address):
	print("Client attempting connection to server at: %s:%s" % [ip_address, _network_config.DEFAULT_SERVER_PORT])
	
	get_tree().connect("connection_failed", self, "_on_connection_failed_internal")
	get_tree().connect("connected_to_server", self, "_on_connection_succeeded_internal")
	
	var create_client_result = _network.create_client(ip_address, _network_config.DEFAULT_SERVER_PORT, 0, 0)
	if create_client_result == OK:
		get_tree().set_network_peer(_network)
	else:
		_on_connection_failed_internal()
	
func _on_connection_failed_internal():
	_client_connected = false
	push_error("Client failed to connect to server")
	call("_on_connection_failed")
	
func _on_connection_succeeded_internal():	
	_client_connected = true
	print("Client connected successfully to server")
	call("_on_connection_succeeded")
	
func _on_client_is_server_internal():	
	_client_connected = true
	_on_peer_connected_internal(0)
	print("Client is also the server")
	call("_on_connection_succeeded")
	
func _report_input(input : NetworkInput) -> void:
	var serialized_input = input.serialize()
	if _local_peer_is_server():
		_on_input_reported_internal(serialized_input)
	else:
		rpc_unreliable_id(0, "_on_input_reported_internal", serialized_input)

#func _on_reported_input_processed(input_array): # TODO: dont keep sending the client input if it has already been processed
#	pass
		
remote func _on_snapshot_recieved_internal(_serialized_snapshot : Dictionary):
	# TODO: deserialize the snapshot properly here once we are serializing
	var snapshot : Snapshot = Snapshot.new().deserialize(_entity_classes, _serialized_snapshot)
	server_snapshot_manager.add_snapshot(snapshot)
	call("_on_snapshot_recieved", snapshot)

remote func _on_confirm_connection_internal(peer_id : int):
	_local_peer_id = peer_id
	call("_on_confirm_connection", peer_id)

remote func _on_peer_disconnect_reported_internal(peer_id : int):
	call("_on_peer_disconnect_reported", peer_id)

func _send_message(msg: String) -> void:
	if _local_peer_is_server():
		_on_message_received_from_client_internal(msg)
	else:
		rpc_id(0, "_on_message_received_from_client_internal", msg)

remote func _on_message_received_from_server_internal(sender : int, message : String, chat_mode : String, message_color : String, sender_color : String) -> void:
	print("======> [%s]: " % sender, message)


########################################################
### Server functionality ###############################
########################################################

func start_server():
	verify_required_functions(server_required_functions, "This game instance cannot be a server - function %s not implemented")
	
	if _is_client == false && _is_server == false:
		_is_server = true
		
		if _network_config.DEFAULT_DO_PNP:
			print("Configuring UPNP...")
			var upnp_manager = UPNPManager.new(_network_config)
			upnp_manager.connect("upnp_completed_success", self, "_create_server")
			upnp_manager.connect("upnp_completed_failure", self, "_on_upnp_failure")
			upnp_manager.upnp_setup(_network_config.DEFAULT_SERVER_PORT, _network_config.DEFAULT_MAXIMUM_CONNECTIONS)
		else:
			print("Skipping UPNP Configuration...")
			_create_server(_network_config.DEFAULT_SERVER_PORT, _network_config.DEFAULT_MAXIMUM_CONNECTIONS)
	else:
		push_error("Cannot start a server if a client or a server is already started.")
	
func _create_server(server_port : int, max_connections : int):
	var create_server_result = _network.create_server(server_port, max_connections)
	if create_server_result == OK:
		var args = Array(OS.get_cmdline_args()) #TODO: abstract this into a commandline manager
		for arg in args:
			var formatted_arg_array = arg.split("=")
			print(formatted_arg_array)
			if formatted_arg_array.size() == 2 && formatted_arg_array[0] == "-bind-ip":
				var bind_ip = formatted_arg_array[1]
				_network.set_bind_ip(bind_ip)
				print("Using command line specified bind ip: " + bind_ip)
			
		get_tree().set_network_peer(_network)
		print("Server started (Running at %s ticks per second on port %s)" % [Engine.iterations_per_second, server_port])
		_server_connected = true
		
		_network.connect("peer_connected", self, "_on_peer_connected_internal")
		_network.connect("peer_disconnected", self, "_on_peer_disconnected_internal")
	elif create_server_result == ERR_ALREADY_IN_USE:
		push_error("Cannot create server - server already in use")
		_server_connected = false
		call("_on_server_creation_error", create_server_result)
	elif create_server_result == ERR_CANT_CREATE:
		push_error("Cannot create server")
		_server_connected = false
		call("_on_server_creation_error", create_server_result)
		
func _on_upnp_failure_internal():
	push_error("UPNP failed to configure")
	_server_connected = false
	call("_on_server_creation_error", ERR_CANT_CREATE)
	
func _on_peer_connected_internal(peer_id):
	print("Peer connected with id: %s" % peer_id)
	call("_on_peer_connected", peer_id)
	if _local_peer_is_server():
		_on_confirm_connection_internal(peer_id)
	else:	
		rpc_unreliable_id(peer_id, "_on_confirm_connection_internal", peer_id)
	
func _on_peer_disconnected_internal(peer_id):
	print("Peer disconnected with id: %s" % peer_id)
	call("_on_peer_disconnected", peer_id)
	rpc_unreliable("_on_peer_disconnect_reported_internal", peer_id)
	if _local_peer_is_server():
		_on_peer_disconnect_reported_internal(peer_id)
	
func _send_snapshot(snapshot : Snapshot):
	var serialized_snapshot : Dictionary = snapshot.serialize()
	rpc_unreliable("_on_snapshot_recieved_internal", serialized_snapshot)

remote func _on_input_reported_internal(serialized_input : Dictionary):
	var input = NetworkInput.new().deserialize(serialized_input)
	var entity_id = get_tree().get_rpc_sender_id()
	server_input_manager.add_input(entity_id, input)
#	call("_on_input_reported", input)

#func _report_processed_input():
#	# TODO: send processed input back to players
#	if _local_peer_is_server():
#		_on_message_received_from_client_internal(msg, mode)
#	else:
#	#rpc_id(1, "_on_reported_input_processed", input_id, input)	
#	pass

remote func _on_message_received_from_client_internal(msg : String, mode: String = "normal") -> void:
	# TODO: Use the mode here for chat channels
	var sender_peer_id : int = get_tree().get_rpc_sender_id()
	_broadcast_message(msg, sender_peer_id, mode)
	
func _broadcast_message(message : String, sender : int = 0, chat_mode : String = "normal", message_color = '#888888', sender_color = '#888888') -> void:
	rpc("_on_message_received_from_server_internal", sender, message, chat_mode, message_color, sender_color)
	if _local_peer_is_server():
		_on_message_received_from_server_internal(sender, message, chat_mode, message_color, sender_color)
	
####################################################
### Processing functionality #######################
####################################################

func _ready():
	print("Networking Manager started...")
	
	var entity_classes : Array = call("_on_request_entity_classes")
	for entity_class in entity_classes:
		_entity_classes[entity_class.get_class_name()] = entity_class
		
	interpolation_parameters = call("_on_interpolation_parameters_requested")

func _local_peer_is_server():
	return _is_client && _is_server

func _physics_process(delta):
	_physics_process_tick += 1
	# Server processing
	if _server_connected:
		# process recieved client input # TODO : thread this for each player?
		for peer_id in server_input_manager.get_ids():
			# TODO: need to supply more options so I can do raycasts here and stuff
			var sorted_input_buffer = server_input_manager.get_and_clear_input_buffer(peer_id)
			if sorted_input_buffer.size() > 0:
				call("_process_inputs", delta, peer_id, sorted_input_buffer)
				server_input_manager.set_last_processed_input_id(peer_id, sorted_input_buffer[sorted_input_buffer.size() - 1].id)
		
		# send processed input back to client ?????????? TODO: this, later lol
		
		# create and save snapshot
		var entities : Array = call("_on_request_entities")
		var snapshot = server_snapshot_manager.create_snapshot(entities, server_input_manager.get_last_processed_input_ids())
		server_snapshot_manager.add_snapshot(snapshot)
		# send snapshot to clients
		_send_snapshot(snapshot)
			
	# Client processing
	if _client_connected:
		# server reconcile aka interpolate/extrapolate other entities
		var interpolated_snapshot = server_snapshot_manager.calculate_interpolation(interpolation_parameters)
		if interpolated_snapshot == null:
			print("No snapshot found. Skipping interpolation...")
		else:
			for entity in interpolated_snapshot.state:
				if !_local_peer_is_server() && entity.id != _local_peer_id:
					call("_on_update_local_entity", delta, entity)
					
#		# gather inputs and send them to the server
#		var input_data : Dictionary = call("_on_input_data_requested")
#		var input : NetworkInput = NetworkInput.new(_physics_process_tick, delta, server_snapshot_manager.get_server_time(), input_data)
#		client_input_manager.add_input(_local_peer_id, input)
#		_report_input(input)
#
#		# client side predict
#		call("_on_client_side_predict", delta, input)
		
		if !_local_peer_is_server():
			var entities : Array = call("_on_request_entities")
			var snapshot = client_snapshot_manager.create_snapshot(entities, {})
			client_snapshot_manager.add_snapshot(snapshot)
			
			var latest_server_snapshot : Snapshot = server_snapshot_manager.vault.get_latest_snapshot()
#			var closest_client_snapshot = client_snapshot_manager.vault.get_closest_snapshot(latest_server_snapshot.time)
			var closest_client_snapshot : InterpolatedSnapshot = client_snapshot_manager.calculate_interpolation(interpolation_parameters)
			if latest_server_snapshot != null && closest_client_snapshot != null && latest_server_snapshot.is_valid():
				call("_on_server_reconcile", delta, latest_server_snapshot, closest_client_snapshot, client_input_manager.get_input_buffer(_local_peer_id)) # TODO: left off here <================================================
	
func _process(delta):
	_process_tick += 1
	# Client processing
	if _client_connected:
		# gather inputs and send them to the server
		var input_data : Dictionary = call("_on_input_data_requested")
		var input : NetworkInput = NetworkInput.new(_physics_process_tick, delta, server_snapshot_manager.get_server_time(), input_data)
		client_input_manager.add_input(_local_peer_id, input)
		_report_input(input)
		
		# client side predict
		call("_on_client_side_predict", delta, input)
		
				
		
