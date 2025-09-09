extends Node2D

class_name TurnManager

var Players = []
var numc_player = 0

func setup():
	Players = [$Player1, $Player2]
	start_round()
func _ready():
	unit.connect("No actíons left",self,"next_player")	
	
func start_round():
	for p in Players:
		p.activate_units()
	numc_player = 0
	print("Začíná nové kolo")
	start_turn()
func start_turn():
	var  current_player = Players[numc_player]
	if current_player.has_units_active():
		print("Hraje: ", current_player.name)
		current_player.start_turn()
	else:
		end_turn
		
func end_turn():
	numc_player = ( numc_player + 1) % Players.size()
	if Players.any(func(p): return p.has_units_active()):
		start_turn()
	else:
		print("Konec kola!")
		start_round()
					
