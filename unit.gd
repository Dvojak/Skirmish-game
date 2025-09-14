extends Node2D
class_name Unit

signal no_actions_left

var actions := 2
var current_id_path: Array[Vector2] = []

func move_along_path(path: Array[Vector2]):
	if actions == 0:
		emit_signal("no_actions_left")
		return
	if path.is_empty():
		return
	current_id_path = path
	actions -= 1

func _physics_process(delta):
	if current_id_path.is_empty():
		return
	var target_position = current_id_path.front()
	global_position = global_position.move_toward(target_position, 1)
	
	if global_position == target_position:
		current_id_path.pop_front()
		if current_id_path.is_empty() and actions == 0:
			emit_signal("no_actions_left")
