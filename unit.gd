
extends Node2D
class_name Unit

@onready var tile_map =  $"../TileMap"

var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]

var activated = false
var actions = 2
var movement_points = 5
signal no_actions_left

func _ready():
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16 ,16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	position = tile_map.map_to_local(tile_map.local_to_map(global_position))
	
	

	
func _physics_process(delta):
	if current_id_path.is_empty():
		return
	var target_position = tile_map.map_to_local(current_id_path.front())
	global_position = global_position.move_toward(target_position, 1)
	
	if global_position == target_position:
		current_id_path.pop_front()
func reset_activation():
	activated = false

func activate():
	if activated:
		return
	print("Jednotka ", name, " je aktivována!")
	activated = true
	actions = 2

func move_to(target_tile: Vector2):
		if current_id_path.is_empty() and actions == 0:
			emit_signal("no_actions_left")
			return
		var id_path = astar_grid.get_id_path(
			tile_map.local_to_map(global_position),
			tile_map.local_to_map(target_tile)
		).slice(1)
		if id_path.size() > movement_points:
			id_path = id_path.slice(0, movement_points)
		if id_path.is_empty() == false:
			current_id_path = id_path
			actions -= 1
			
