extends KinematicBody

var SPEED : float = 10.0
var GRAVITY = -25

var velocity = Vector3.ZERO

func move(delta : float, input : NetworkInput):
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
	velocity.y += GRAVITY * delta
	
#	velocity += move_vector * ACCELERATION
#	move_and_slide(velocity * delta)

	velocity = move_and_slide_with_snap(velocity, Vector3(0, -0.3, 0), Vector3.UP, true)
	
