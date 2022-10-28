extends Entity

class_name ShotEntity

const interpolation_parameters = []

var peer_id : int
var time : int
var origin : Vector3
var normal : Vector3
var hit : int
var color : Color = Color.white

func _init(attributes : Dictionary):
	self.peer_id = attributes.peer_id
	self.time = attributes.time
	self.origin = attributes.origin
	self.normal = attributes.normal
	if "hit" in attributes:
		self.hit = attributes.hit
	if "color" in attributes:
		self.color = attributes.color

static func get_class_name():
	return "ShotEntity"

func serialize():
	return {
		"peer_id": peer_id,
		"time": time,
		"origin": origin,
		"normal": normal,
		"hit": hit,
	}

func deserialize(serialized_snapshot : Dictionary):
	return get_script().new({
		"peer_id": serialized_snapshot["peer_id"], 
		"time": serialized_snapshot["time"], 
		"origin": serialized_snapshot["origin"],
		"normal": serialized_snapshot["normal"],
		"hit": serialized_snapshot["hit"], 
		"color": serialized_snapshot["color"],
	})
