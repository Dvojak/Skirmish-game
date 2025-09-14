extends Node2D

class_name TurnManager

@onready var unit = $player/unit
@onready var tile_map =  $"../TileMap"
var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]

var Players = []
var numc_player = 0
var selected_unit: Unit = null

func setup():
	Players = [$Player1, $Player2]
	start_round()
func _ready():
	unit.connect("no_actions_left",Callable(self, "_on_finished_action"))	
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16 ,16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	position = tile_map.map_to_local(tile_map.local_to_map(global_position))
	
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
		end_turn()
func _get_unit_under_mouse() -> Unit:
	var world_pos = get_viewport().get_camera_2d().screen_to_world(get_viewport().get_mouse_position())
	var space = get_world_2d().direct_space_state
	var result = space.intersect_point(world_pos)
	if result.size() > 0 and result[0].collider is Unit:
		return result[0].collider	
	return null
func _get_tile_under_mouse() -> Vector2:
	var world_pos = get_viewport().get_camera_2d().screen_to_world(get_viewport().get_mouse_position())
	var tile_coords = tile_map.local_to_map(world_pos)
	return tile_map.map_to_local(tile_coords)
	
func _on_finished_action():
	print("Jednotka dokončila všechny akce!")
	end_turn()	

func _input(event):
	if event.is_action_pressed("move") and selected_unit:
		var target_tile = _get_tile_under_mouse()
		var path = astar_grid.get_id_path(
			tile_map.local_to_map(selected_unit.global_position),
			tile_map.local_to_map(target_tile)
		).slice(1)

		if path.size() > selected_unit.movement_points:
			path = path.slice(0, selected_unit.movement_points)

		# převedeme na souřadnice v herním světě
		var world_path: Array[Vector2] = []
		for p in path:
			world_path.append(tile_map.map_to_local(p))

		selected_unit.move_along_path(world_path)

		
func end_turn():
	numc_player = ( numc_player + 1) % Players.size()
	if Players.any(func(p): p.has_units_active()):
		start_turn()
	else:
		print("Konec kola!")
		start_round()
					
