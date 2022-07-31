extends Control

const HITMARKER_DISSAPEAR_RATE : float = 0.1

func _ready():
	$Hitmarker.set("modulate", Color(1, 1, 1, 0))

func _physics_process(delta):
	var window_width = get_viewport().get_visible_rect().size.x
	var window_height = get_viewport().get_visible_rect().size.y
	var pos_x = (window_width / 2) - ($Crosshair.rect_size.x / 2)
	var pos_y = (window_height / 2) - ($Crosshair.rect_size.y / 2)
	$Crosshair.rect_position = Vector2(pos_x, pos_y)
	pos_x = (window_width / 2) - ($Hitmarker.rect_size.x / 2)
	pos_y = (window_height / 2) - ($Hitmarker.rect_size.y / 2)
	$Hitmarker.rect_position = Vector2(pos_x, pos_y)

func _process(delta):
	var alpha = $Hitmarker.get("modulate").a
	$Hitmarker.set("modulate", Color(1, 1, 1, alpha - HITMARKER_DISSAPEAR_RATE))

func show_hitmarker():
	$Hitmarker.set("modulate", Color(1, 1, 1, 1))
