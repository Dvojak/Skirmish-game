extends Node2D
class_name Unit

signal no_actions_left
signal movement_finished
signal unit_selected


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

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("unit_selected", self)


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

func apply_damage(amount: int) -> void:
	health_points -= amount
	print("%s dostal %d dmg. HP nyní: %d" % [self.name, amount, health_points])

	if health_points <= 0:
		queue_free()
		print("%s zemřel!" % name)

func is_engaged(tile_map: TileMapLayer, units_container: Node) -> bool:
	var my_tile = tile_map.local_to_map(global_position)

	var dirs = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	for dir in dirs:
		var check_tile = my_tile + dir
		for u in units_container.get_children():
			if u == self:
				continue
			if u.oowner != oowner:
				if tile_map.local_to_map(u.global_position) == check_tile:
					return true
	return false
