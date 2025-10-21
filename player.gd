extends Node2D
class_name Player

var units: Array[Unit] = []

func _ready():
	print(name, " je připravený s jednotkami: ", units)
	
func has_units_to_activate() -> bool:
	return units.any(func(u): return u.actions > 0)

func start_turn():
	print(name, ": vyber jednotku k aktivaci.")

func reset_units():
	for u in units:
		u.actions = u.max_actions
