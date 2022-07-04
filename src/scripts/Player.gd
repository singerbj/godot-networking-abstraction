extends KinematicBody

var SPEED : float = 10.0
var GRAVITY : float = -9.8

var server_side = false
var velocity = Vector3.ZERO
var last_physics_transform

func _enter_tree():
	last_physics_transform = global_transform

func move(input : NetworkInput):
	last_physics_transform = global_transform
	
	var move_vector = Vector3.ZERO
	for button in input["data"].keys():
		if button == "m_forward":
			move_vector.z -= 1
		if button == "m_backward":
			move_vector.z += 1
		if button == "m_left":
			move_vector.x -= 1
		if button == "m_right":
			move_vector.x += 1
		
	move_vector = move_vector.normalized()
		
	var desired_velocity: Vector3 = move_vector * SPEED
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity.y += GRAVITY
	
	velocity = move_and_slide_with_snap(velocity, Vector3(0, -0.3, 0), Vector3.UP, true)
	
func update_transform(transform_from_server : Transform):
	last_physics_transform = global_transform
	transform = transform_from_server

func _process(delta):
	if !server_side:
		var fraction = Engine.get_physics_interpolation_fraction()
		$MeshInstance.global_transform = last_physics_transform.interpolate_with(global_transform, fraction)
	pass
	
