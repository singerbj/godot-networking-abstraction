extends KinematicBody

var ACCELERATION : float = 40.0
const MOVE_SPEED : float = 3.0

var velocity = Vector3(0, 0, 0)

func move(delta : float, input : NetworkInput):
	var move_vector = Vector3(0, 0, 0)
	for button in input["data"].keys():
		if button == "m_forward":
			move_vector.z -= 1
		if button == "m_backward":
			move_vector.z += 1
		if button == "m_left":
			move_vector.x -= 1
		if button == "m_right":
			move_vector.x += 1
		
		move_vector.y -= 1
		
	move_vector = move_vector.normalized()
	
	velocity += move_vector * ACCELERATION
	move_and_slide(velocity * delta)
	
