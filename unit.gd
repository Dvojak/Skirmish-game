extends Node2D
class_name Unit

signal no_actions_left
signal movement_finished


var oowner: Player
var max_actions := 2
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
var move_speed := 100.0 

func _ready():
	set_physics_process(true)

func move_along_path(path: Array[Vector2]) -> void:
	if actions == 0:
		emit_signal("no_actions_left")
		return
	if path.is_empty():
		print("Cesta je prázdná, jednotka se nepohne.")
		return
	
	print("Jednotka se pohybuje po cestě dlouhé: ", path.size())
	actions -= 1


	var tween = create_tween()
	for point in path:
		tween.tween_property(self, "global_position", point, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(Callable(self, "_on_move_finished"))

func _on_move_finished():
	print(" Jednotka dokončila pohyb.")
	emit_signal("movement_finished")
	if actions == 0:
		emit_signal("no_actions_left")


func _physics_process(_delta):
	if current_id_path.is_empty():
		return
	var target_position = current_id_path.front()
	global_position = global_position.move_toward(target_position, move_speed * _delta)
	
	if global_position == target_position:
		current_id_path.pop_front()
		if current_id_path.is_empty():
			print("Jednotka dorazila na místo.")
			if actions == 0:
				emit_signal("no_actions_left")
			emit_signal("movement_finished")
