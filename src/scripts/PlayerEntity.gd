extends Entity

class_name PlayerEntity

var transform : Transform
var velocity : Vector3

func _init(attributes : Dictionary):
	self.id = attributes.id
	self.transform = attributes.transform
	self.velocity = attributes.velocity

static func get_class_name():
	return "PlayerEntity"

func serialize():
	return {
		"id": id,
		"transform": transform,
		"velocity": velocity
	}

func deserialize(serialized_snapshot : Dictionary):
	return get_script().new({
		"id": serialized_snapshot["id"], 
		"transform": serialized_snapshot["transform"], 
		"velocity": serialized_snapshot["velocity"]
	})
