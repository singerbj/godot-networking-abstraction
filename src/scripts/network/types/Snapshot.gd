extends Node

class_name Snapshot

var id : String
var time : int
var state : Array = []

func _init(_id : String, _time : int, _state : Array):
	self.id = _id
	self.time = _time
	self.state = _state
	
