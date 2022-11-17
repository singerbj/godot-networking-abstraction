extends KinematicBody

var player_id : int

const SPEED : float = 8.0
const ACCELERATION_DEFAULT : float = 7.0
const ACCELERATION_AIR : float = 1.0
const GRAVITY : float = 25.0
const DEFAULT_JUMP_INERTIA : float = 200.0
const SENS_MULTIPLIER : float = 0.03
const STARTING_HEAD_ANGLE : float = 0.0
const JUMP_FORCE : float = 10.0
const MAX_HEALTH : float = 1000.0

const MAX_BOT_MOVE_TIME = 60
var is_bot = false
var bot_move_time = 0
var bot_move_key = "m_left"

var is_local_player : bool = false
var head_nod_angle : float = STARTING_HEAD_ANGLE
#var velocity = Vector3.ZERO

onready var accel : float = ACCELERATION_DEFAULT
var mouse_sense = 0.1
var snap
var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()

var last_transform : Transform
var last_rotation : Vector3
var last_head_nod_angle : float
var current_transform : Transform
var current_rotation : Vector3
var current_head_nod_angle : float

var health : float = MAX_HEALTH

func _enter_tree():
	last_transform = transform
	last_rotation = rotation
	last_head_nod_angle = head_nod_angle
	
	if is_local_player:
		set_physics_interpolation_mode(Node.PHYSICS_INTERPOLATION_MODE_OFF)
		
func _process(delta):
	$HealthBar/Viewport/TextureProgress.value = (health / MAX_HEALTH) * 100

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
	
	var input_data = input["data"]
	if self.is_bot:
		bot_move_time += 1
		if bot_move_time > MAX_BOT_MOVE_TIME:
			bot_move_time = 0
			if bot_move_key == "m_left":
				bot_move_key = "m_right"
			else:
				bot_move_key = "m_left"
		input_data[bot_move_key] = true
			
	
	for button in input_data.keys():
		if button == "m_forward":
			move_vector += -global_transform.basis.z
		if button == "m_backward":
			move_vector += global_transform.basis.z
		if button == "m_left":
			move_vector += -global_transform.basis.x
		if button == "m_right":
			move_vector += global_transform.basis.x
		if button == "jump": # && is_on_floor():
			jump = true
	
	#jumping and gravity
	if is_on_floor():
		snap = -get_floor_normal()
		accel = ACCELERATION_DEFAULT
		gravity_vec = Vector3.ZERO
	else:
		snap = Vector3.DOWN
		accel = ACCELERATION_AIR
		gravity_vec += Vector3.DOWN * GRAVITY * local_delta
		
	if jump and is_on_floor():
		snap = Vector3.ZERO
		gravity_vec = Vector3.UP * JUMP_FORCE
	
	# make it move
	velocity = velocity.linear_interpolate(move_vector * SPEED, accel * local_delta)
	movement = velocity + gravity_vec
	movement = movement * (input.delta / local_delta)
	
	move_and_slide_with_snap(movement, snap, Vector3.UP)
	
func update_local_player_from_server(entity : PlayerEntity):
	health = entity.health
		
func update_peer_player_from_server(entity : PlayerEntity):
	transform = entity.transform
	rotation = entity.rotation
	head_nod_angle = entity.head_nod_angle
	if $Camera != null:
		$Camera.rotation_degrees.x = entity.head_nod_angle
		
	update_local_player_from_server(entity)
		
func take_damage(damage : float):
	health -= damage
	
func get_camera() -> Node:
	return $Camera

func set_camera_active():
	if $Camera != null:
		$Camera.make_current()
	
	
