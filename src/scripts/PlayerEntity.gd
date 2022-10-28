extends Entity

class_name PlayerEntity

const interpolation_parameters = [
	"transform.origin.x", "transform.origin.y", "transform.origin.z",
	"rotation.x", "rotation.y", "rotation.z",
	"head_nod_angle"
]

var transform : Transform
var velocity : Vector3
var rotation : Vector3
var head_nod_angle : float
var health : float

func _init(attributes : Dictionary):
	self.id = attributes.id
	self.transform = attributes.transform
	self.velocity = attributes.velocity
	self.rotation = attributes.rotation
	self.head_nod_angle = attributes.head_nod_angle
	self.health = attributes.health

static func get_class_name():
	return "PlayerEntity"

func serialize():
	return {
		"id": id,
		"transform": transform,
		"velocity": velocity,
		"rotation": rotation,
		"head_nod_angle": head_nod_angle,
		"health": health
	}

func deserialize(serialized_snapshot : Dictionary):
	return get_script().new({
		"id": serialized_snapshot["id"], 
		"transform": serialized_snapshot["transform"], 
		"velocity": serialized_snapshot["velocity"], 
		"rotation": serialized_snapshot["rotation"], 
		"head_nod_angle": serialized_snapshot["head_nod_angle"],
		"health": serialized_snapshot["health"],
	})
