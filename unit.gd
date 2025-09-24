extends Node2D
class_name Unit

signal no_actions_left

# Unit characteristics
var actions := 2
var movement_points := 4
var health_points:=  10
var toughness := 4
var far:= 1
var strenght := 4
var attack := 3
var hit := 4
var crit := 6
var type :=  "Standart"



var current_id_path: Array[Vector2] = []

func move_along_path(path: Array[Vector2]):
	if actions == 0:
		emit_signal("no_actions_left")
		return
	if path.is_empty():
		return
	current_id_path = path
	actions -= 1

func _physics_process(_delta):
	if current_id_path.is_empty():
		return
	var target_position = current_id_path.front()
	global_position = global_position.move_toward(target_position, 1)
	
	if global_position == target_position:
		current_id_path.pop_front()
		if current_id_path.is_empty() and actions == 0:
			emit_signal("no_actions_left")
