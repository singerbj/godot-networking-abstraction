extends Entity

class_name PlayerEntity

var transform : Transform

func _init(attributes : Dictionary):
	self.id = attributes.id
	self.transform = attributes.transform

static func get_class_name():
	return "PlayerEntity"

func serialize():
	return {
		"id": id,
		"transform": transform
	}

func deserialize(serialized_snapshot : Dictionary):
	return get_script().new(serialized_snapshot["id"], serialized_snapshot["transform"])
