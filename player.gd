extends Node2D
var units = []

func _ready():
	units = [$Unit1, $Unit2, $Unit3]

func reset_units():
	for u in units:
		u.reset_activation()

func has_units_to_activate() -> bool:
	for u in units:
		if not u.activated:
			return true
	return false

func start_turn():
	# Tady můžeš dát hráči možnost vybrat jednotku
	print("Vyber jednotku k aktivaci.")
