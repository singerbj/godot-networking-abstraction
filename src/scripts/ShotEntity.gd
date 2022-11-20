extends Entity

class_name ShotEntity

const interpolation_parameters = []

var peer_id : int
var time : int
var origin : Vector3
var normal : Vector3
var hit : int
var color : Color = Color.white

func _init(attributes):
	var attr_dict : Dictionary
	if attributes is Dictionary:
		attr_dict = attributes
	else:
		attr_dict = deserialize(attributes)
		
	self.peer_id = attr_dict.peer_id
	self.time = attr_dict.time
	self.origin = attr_dict.origin
	self.normal = attr_dict.normal
	if "hit" in attr_dict:
		self.hit = attr_dict.hit
	if "color" in attr_dict:
		self.color = attr_dict.color

static func get_class_name():
	return "ShotEntity"

func serialize():
	var buffer := StreamPeerBuffer.new()
	
	buffer.put_u32(id)
	buffer.put_u32(time)
	NetworkUtil.serialize_vector3(buffer, origin)
	NetworkUtil.serialize_vector3(buffer, normal)
	buffer.put_u32(hit)
	NetworkUtil.serialize_color(buffer, color)
	
	buffer.resize(buffer.get_position())
	return buffer.data_array

func deserialize(serialized : PoolByteArray):
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)
	
	return get_script().new({
		"peer_id": buffer.get_u32(), 
		"time": buffer.get_u32(),
		"origin": NetworkUtil.deserialize_vector3(buffer),
		"normal": NetworkUtil.deserialize_vector3(buffer),
		"hit": buffer.get_u32(),
		"color": NetworkUtil.deserialize_color(buffer),
	})
