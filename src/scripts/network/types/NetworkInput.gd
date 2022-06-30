extends Node

class_name NetworkInput

var id : int
var time : int
var data : Dictionary

func _init(_id : int = 0, _time : int = 0, _data : Dictionary = {}):
	self.id = _id
	self.time = _time
	self.data = _data
	
func _ready():
	if !has_method("serialize"):
		push_error("This entity does not have a serialize function")
	if !has_method("deserialize"):
		push_error("This entity does not have a deserialize function")
	
func serialize():
	return {
		"id": id,
		"time": time,
		"data": data
	}

func deserialize(serialized_snapshot : Dictionary):
	return get_script().new(serialized_snapshot["id"], serialized_snapshot["time"], serialized_snapshot["data"])
	
