extends Node

class_name Snapshot

var id : String
var time : int
var state : Array = []

func _init(_id : String = "", _time : int = -1, _state : Array = []):
	self.id = _id
	self.time = _time
	self.state = _state
	
func serialize():
	var serialized_state = []
	for entity in state:
		serialized_state.append({ 
			"name": entity.get_class_name(),
			"data": entity.serialize() 
		})
	return {
		"id": id,
		"time": time,
		"state": serialized_state
	}

func deserialize(entity_classes : Dictionary, serialized_snapshot : Dictionary):
	var deserialized_state = []
	for serialized_entity in serialized_snapshot["state"]:
		deserialized_state.append(entity_classes[serialized_entity["name"]].new(serialized_entity["data"]))
	return get_script().new(serialized_snapshot["id"], serialized_snapshot["time"], deserialized_state)
	
