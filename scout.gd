extends Unit
class_name Scout

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	movement_points = 6
	health_points = 8
	toughness = 3
	strenght = 3
	attack = 4
	type = "Scout"
