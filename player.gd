extends Node2D
class_name Player

var units:= []

func _ready():
	units = get_children().filter(func(c): return c is Unit)

func reset_units():
	for u in units:
		u.actions = u.actions
		

func has_units_to_activate() -> bool:
	return units.any(func(u): return u.actions > 0)

func start_turn():
	print("Vyber jednotku k aktivaci.")
