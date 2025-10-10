extends Node2D

class_name TurnManager


@onready var tile_map: TileMapLayer = get_node_or_null("../TileMap/TileMapLayer")
var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]

var players: Array[Player] = []
var numc_player = 0
var selected_unit: Unit = null


func _ready():
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16 ,16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	position = tile_map.map_to_local(tile_map.local_to_map(global_position))
	players = []
	for c in get_children():
		if c is Player:
			var p: Player = c
			players.append(p)
			for u in p.units:
				u.connect("no_actions_left", Callable(self, "_on_finished_action"))
	start_round()
	
func start_round():
	for p in players:
		p.reset_units()
	numc_player = 0
	print("Začíná nové kolo")
	start_turn()
func start_turn():
	var  current_player = players[numc_player]
	if current_player.has_units_to_activate():
		print("Hraje: ", current_player.name)
		current_player.start_turn()
	else:
		end_turn()
func _get_unit_under_mouse() -> Unit:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return null

	var mouse_pos = get_viewport().get_mouse_position()
	var world_pos = camera.get_screen_transform().affine_inverse() * mouse_pos
	var space = get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space.intersect_point(query)
	if result.size() > 0 and result[0].collider is Unit:
		return result[0].collider	
	return null
func _get_tile_under_mouse() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return Vector2.ZERO

	var mouse_pos = get_viewport().get_mouse_position()
	var world_pos = camera.get_screen_transform().affine_inverse() * mouse_pos
	var tile_coords = tile_map.local_to_map(world_pos)
	return tile_map.map_to_local(tile_coords)
	
func _on_finished_action():
	print("Jednotka dokončila všechny akce!")
	end_turn()	

func _input(event):
	if event.is_action_pressed("select"):
		var u = _get_unit_under_mouse()
		if u and u  in players[numc_player].units:
			selected_unit = u
			print("Vybral jsi jednotku: ", u.type)
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
	numc_player = ( numc_player + 1) % players.size()
	if players.any(func(p): p.has_units_active()):
		start_turn()
	else:
		print("Konec kola!")
		start_round()
					
