extends Node

class_name Entity

var id : int

func _ready():
	if !has_method("get_class_name"):
		push_error("This entity does not have a get_class_name function")
	elif typeof(call("get_class_name")) != TYPE_STRING:
		push_error("get_class_name does not return string for this entity")
	if !has_method("serialize"):
		push_error("This entity does not have a serialize function")
	if !has_method("deserialize"):
		push_error("This entity does not have a edserialize function")


