extends Node

class_name InterpolatedSnapshot

var _state : Array = []
var _percentage : float
var _older : String
var _newer : String

func _init(state : Array, percentage : float, older : String, newer : String):
	_state = state
	_percentage = percentage
	_older = older
	_newer = newer
