extends Node2D

class_name LineDrawer

var DEFAULT_THICKNESS = 4.0
var LINE_SHRINK_AMOUNT = 10

class Line:
	var color
	var thickness = 4.0
	var start
	var end
	var time
	
var lines : Dictionary = {}
var camera : Camera
var next_id : int = 0

func _ready():
	set_process(true)

func _draw():
	camera = get_viewport().get_camera()
	var line : Line
	for key in lines.keys():
		line = lines[key]
		var adjusted_start = camera.unproject_position(line.start)
		var adjusted_end = camera.unproject_position(line.end)
		
		draw_line(adjusted_start, adjusted_end, line.color, line.thickness)

func _process(delta):
	var to_delete = []
	var line : Line
	for key in lines.keys():
		line = lines[key]
		line.thickness = line.thickness - (delta * LINE_SHRINK_AMOUNT)
		if line.thickness < 1:
			lines.erase(key)

	update()

func draw_line_3d(start, end, color, thickness = DEFAULT_THICKNESS, time = OS.get_system_time_msecs()):
	var new_line = Line.new()
	new_line.color = color
	new_line.start = start
	new_line.end = end
	new_line.thickness = thickness
	new_line.time = time
	
	next_id += 1
	lines[next_id] = new_line
