extends Entity

class_name PlayerEntity

var transform : Transform

func _init(_id : int, _transform : Transform):
	self.id = _id
	self.transform = _transform

