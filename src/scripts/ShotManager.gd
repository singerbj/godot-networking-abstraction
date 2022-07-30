extends Spatial

onready var client_shots : Array = []
onready var server_shots : Array = []
var shot_starting_distance = 2
var ray_length = 100

func clear_shots() -> void:
	client_shots = []
	server_shots = []

func get_client_shots() -> Array:
	return client_shots
	
func get_server_shots() -> Array:
	return server_shots
	
#func fire_shots(shots_to_fire):
#	clear_shots()
#
#	# save the current player location
#	for pid in ServerData.players:
#		var player = ServerData.players[pid]
#		player.stash_current_transform()
#
#	var players_who_hit = []
##	var players_who_got_hit = []
#	for shot in shots_to_fire:
#		if can_fire(shot["pid"]):
#			# move players to the correct location to do hit detection at the correct time
#			for pid in ServerData.players:
#				var player = ServerData.players[pid]
#
#				if pid != shot["pid"]:
#					print("==============================")				
#					player.move_to_interpolated_location(shot["input"]["timestamp"] + (SharedData.INTERPOLATION_OFFSET), false)
#					print("==============================")				
#
#				else:				
#					player.move_to_interpolated_location(shot["input"]["timestamp"], true)
#
#			print("------------->", ServerData.players[shot['pid']])
#			var hit = fire_shot(shot["pid"], ServerData.players[shot["pid"]])
#			if hit && !players_who_hit.has(shot["pid"]):
#				players_who_hit.append(shot["pid"])
#
#	# go back to the saved player location
#	var player_locations = []
#	for pid in ServerData.players:
#		var player = ServerData.players[pid]
#		player_locations.append(player.transform.origin)
#		player.revert_to_stashed_transform()
#
#	return [players_who_hit, player_locations]
#
#var player_last_shots = {}
#func can_fire(pid : int):
#	return !(pid in player_last_shots) || (OS.get_system_time_msecs() - 0) > player_last_shots[pid]
#
func fire_server_shot(shot : ShotEntity, exclude : Array = []) -> ShotEntity:
	var from = shot.origin + shot.normal * shot_starting_distance
	var to = shot.origin + shot.normal * ray_length
	
	# use global coordinates, not local to node
	var space_state = get_world().direct_space_state
	var all_results = []
	var all_colliders = []
	var hit_player = false
	var continue_casting = true
	
	while(continue_casting):		
		var result = space_state.intersect_ray(from, to, exclude + all_colliders)
		if 'collider_id' in result:
			all_results.append(result)
			all_colliders.append(result.collider)
		else:
			continue_casting = false
		
	var color = Color(0, 0, 0.5)
	if all_results.size() > 0:
		color = Color(0.5, 0, 0)
		to = all_results[0].position
		
		if "is_player" in all_colliders[0]:
			hit_player = true
			color = Color(0, 0.5, 0.5)
	
	shot.color = color
	shot.hit = hit_player
		
	client_shots.append(shot)
	_render_shot(from, to, color)
	
	return shot

func fire_client_shot(shot : ShotEntity, server_debug : bool = false):
	server_shots.append(shot)
	
	var from = shot.origin + shot.normal * shot_starting_distance
	var to = shot.origin + shot.normal * ray_length
	var color = shot.color
	if server_debug:
		color = Color.aqua
	
	_render_shot(from, to, color)
	
func _render_shot(from : Vector3, to : Vector3, color : Color):
	DrawLine3d.draw_line_3d(from, to, color)
	

				
