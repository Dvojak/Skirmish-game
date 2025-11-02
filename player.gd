extends Node2D
class_name Player

var units: Array[Unit] = []

func _ready():
	print(name, " je připravený s jednotkami: ", units)
	
func refresh_units_list():
	var found_units: Array[Unit] = []
	for c in get_children():
		if c is Unit:
			found_units.append(c)
	units = found_units
		
func has_units_to_activate() -> bool:
	return units.any(func(u): return u.actions > 0)

func start_turn():
	print(name, ": vyber jednotku k aktivaci.")

func reset_units():
	for u in units:
		u.actions = u.max_actions
