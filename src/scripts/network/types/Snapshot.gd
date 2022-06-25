extends Node

class_name Snapshot

var _id : String
var _time : int
var _state : Array = []

func _init(id : String, time : int, state : Array):
	_id = id
	_time = time
	_state = state
	
