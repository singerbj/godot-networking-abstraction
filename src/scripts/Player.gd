extends KinematicBody

const is_player : bool = true;

const SPEED : float = 8.0
const GRAVITY : float = -9.8
const DEFAULT_JUMP_INERTIA : float = 200.0
const SENS_MULTIPLIER : float = 0.03
const STARTING_HEAD_ANGLE : float = 0.0

var is_local_player : bool = false
var head_nod_angle : float = STARTING_HEAD_ANGLE
var velocity = Vector3.ZERO

var last_transform : Transform
var last_rotation : Vector3
var last_head_nod_angle : float
var current_transform : Transform
var current_rotation : Vector3
var current_head_nod_angle : float

func _enter_tree():
	last_transform = transform
	last_rotation = rotation
	last_head_nod_angle = head_nod_angle
	
	if is_local_player:
		set_physics_interpolation_mode(Node.PHYSICS_INTERPOLATION_MODE_OFF)

func rotate_player_with_input(mouse_motion : Vector2):
	last_rotation = rotation
	last_head_nod_angle = head_nod_angle
	
	# Rotate body around the vertical axis
	rotation_degrees.y -= SENS_MULTIPLIER * mouse_motion.x
	# Rotate head around the horizontal (like nodding)
	head_nod_angle -= SENS_MULTIPLIER * mouse_motion.y
	head_nod_angle = clamp(head_nod_angle, STARTING_HEAD_ANGLE - 80, STARTING_HEAD_ANGLE + 80)
	if $Camera != null:
		$Camera.rotation_degrees.x = head_nod_angle
		
func rotate_player_with_values(rotation_degrees_from_server : float, head_nod_angle_from_server : float):
	last_rotation = rotation
	last_head_nod_angle = head_nod_angle
	
	rotation_degrees.y = rotation_degrees_from_server
	head_nod_angle = head_nod_angle_from_server
	if $Camera != null:
		$Camera.rotation_degrees.x = head_nod_angle_from_server

func move(input : NetworkInput, local_delta : float):
	last_transform = transform
	
	var move_vector = Vector3.ZERO
	var jump = false
	for button in input["data"].keys():
		if button == "m_forward":
			move_vector += -global_transform.basis.z
		if button == "m_backward":
			move_vector += global_transform.basis.z
		if button == "m_left":
			move_vector += -global_transform.basis.x
		if button == "m_right":
			move_vector += global_transform.basis.x
		if button == "jump" && is_on_floor():
			jump = true
		
	move_vector = move_vector.normalized()
	
	var desired_velocity: Vector3 = move_vector * SPEED
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	if jump:
		velocity.y = DEFAULT_JUMP_INERTIA
	else:
		velocity.y = GRAVITY
	
	velocity = velocity * (input.delta / local_delta)
	
	velocity = move_and_slide_with_snap(velocity, Vector3(0, -0.3, 0), Vector3.UP, true)
	
func update_from_server(transform_from_server : Transform, rotation_from_server : Vector3, head_nod_angle_from_server : float):
	transform = transform_from_server
	rotation = rotation_from_server
	head_nod_angle = head_nod_angle_from_server
	if $Camera != null:
		$Camera.rotation_degrees.x = head_nod_angle_from_server

func get_camera() -> Node:
	return $Camera

func set_camera_active():
	if $Camera != null:
		$Camera.make_current()
	
