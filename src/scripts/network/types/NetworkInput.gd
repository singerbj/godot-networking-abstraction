extends Node

class_name NetworkInput

var id : int
var time : int
var data : Dictionary

func _init(_id : int, _time : int, _data : Dictionary):
	self.id = _id
	self.time = _time
	self.data = _data
	
