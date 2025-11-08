extends Node2D
class_name TurnManager

@onready var attack_overlay: TileMapLayer = get_node("../AttackOverlay/TileMapLayer")
@onready var overlay_map: TileMapLayer = get_node("../MovementOverlay/TileMapLayer")
@onready var tile_map: TileMapLayer = get_node_or_null("../TileMap/TileMapLayer")
@onready var units_container = get_node("../Unit")
@onready var player1: Player = get_node("../player1")
@onready var player2: Player = get_node("../player2")
@onready var popup = get_node("../CanvasLayer/UnitStatPopup")


var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
var players: Array[Player] = []
var numc_player = 0
var selected_unit: Unit = null


func _ready():
	# Inicializace A*
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	position = tile_map.map_to_local(tile_map.local_to_map(global_position))
	
	players = [player1, player2]

	for u in units_container.get_children():
		if u is Unit:
			if "_P1" in u.name:
				u.oowner = player1
				player1.units.append(u)
			elif "_P2" in u.name:
				u.oowner = player2
				player2.units.append(u)
			u.connect("no_actions_left", Callable(self, "_on_finished_action"))
			u.connect("movement_finished", Callable(self, "_on_unit_move_finished"))
			u.connect("unit_selected", Callable(popup, "show_stats"))
	
	print("Jednotky přiřazeny:")
	for p in players:
		print(p.name, " má ", p.units.size(), " jednotek.")
		

	
	start_round()


func start_round():
	for p in players:
		p.reset_units()
	numc_player = 0
	print("Začíná nové kolo")
	start_turn()


func start_turn():
	var current_player = players[numc_player]
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
	var current_player = players[numc_player]
	
	if not current_player.has_units_to_activate():
		print(" Hráč", current_player.name, "už nemá žádné jednotky k aktivaci.")
	
	end_turn()

func _on_unit_move_finished():
	overlay_map.clear()
	attack_overlay.clear()
	
	
	var unit = selected_unit
	var unit_pos = tile_map.local_to_map(unit.global_position)

	for u in units_container.get_children():
		if u == unit:
			continue
		if tile_map.local_to_map(u.global_position) == unit_pos:
			print("!! Kontakt s nepřítelem → boj!")
			start_combat(unit, u)
			return



func _input(event):
	if event.is_action_pressed("select"):
		var u = _get_unit_under_mouse()
		if u and u in players[numc_player].units:
			selected_unit = u
			print("Vybral jsi jednotku: ", u.type)
			show_movement_range(u)
			show_attack_range(u)
	elif event.is_action_pressed("move") and selected_unit:
		var clicked_unit = _get_unit_under_mouse()

		if clicked_unit and clicked_unit != selected_unit:
			print("Klikl jsi na jednotku → pokusím se zaútočit")
			try_attack(selected_unit, clicked_unit)
			return

		var target_tile = _get_tile_under_mouse()
		var start = tile_map.local_to_map(selected_unit.global_position)
		var end = tile_map.local_to_map(target_tile)

		var path = astar_grid.get_id_path(start, end).slice(1)
		if path.is_empty():
			print("Žádná cesta nebyla nalezena")
			return

		if path.size() > selected_unit.movement_points:
			path = path.slice(0, selected_unit.movement_points)

		var world_path: Array[Vector2] = []
		for p in path:
			world_path.append(tile_map.map_to_local(p))

		selected_unit.move_along_path(world_path)



func end_turn():
	numc_player = (numc_player + 1) % players.size()
	print("Tah hráče skončil, teď hraje:", players[numc_player].name)
	
	if players[numc_player].has_units_to_activate():
		start_turn()
	else:
		var any_active = false
		for p in players:
			if p.has_units_to_activate():
				any_active = true
				break

		if any_active:
			end_turn()
		else:
			print(" Konec kola, všichni hráči dohráli.")
			start_round()
func show_movement_range(unit: Unit):
	overlay_map.clear()
	var start = tile_map.local_to_map(unit.global_position)
	var reachable_tiles = get_reachable_tiles(start, unit.movement_points)
	for tile in reachable_tiles:
		overlay_map.set_cell(tile, 0, Vector2i.ZERO)

func show_attack_range(unit: Unit):
	attack_overlay.clear()

	var start = tile_map.local_to_map(unit.global_position)

	for x in range(-unit.far, unit.far + 1):
		for y in range(-unit.far, unit.far + 1):
			var offset = Vector2i(x, y)
			var target = start + offset

			# jen políčka v manhattan vzdálenosti
			if abs(x) + abs(y) <= unit.far:
				attack_overlay.set_cell(target, 0, Vector2i.ZERO)
		

func get_reachable_tiles(start: Vector2i, movement: int) -> Array[Vector2i]:
	var visited = {}
	var frontier: Array[Vector2i] = [start]
	var reachable: Array[Vector2i] = []
	visited[start] = 0
	
	while frontier.size() > 0:
		var current = frontier.pop_front()
		var cost = visited[current]
		if cost >= movement:
			continue
		
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var next = current + dir
			if not tile_map.get_used_rect().has_point(next):
				continue
			if visited.has(next):
				continue
			
			visited[next] = cost + 1
			reachable.append(next)
			frontier.append(next)
	
	return reachable
	
func try_attack(attacker: Unit, defender: Unit):
	if attacker.actions <= 0:
		print("Jednotka už nemá akce.")
		return

	var start = tile_map.local_to_map(attacker.global_position)
	var target = tile_map.local_to_map(defender.global_position)

	if start.distance_to(target) > attacker.far:
		print(" Cíl je mimo dosah útoku.")
		return

	start_combat(attacker, defender)
	attacker.actions -= 1
	print("Akce zbývající:", attacker.actions)

	if attacker.actions <= 0:
		_on_finished_action()  # konec tahu jednotky	

func start_combat(attacker: Unit, defender: Unit):
	print(" Boj začíná:", attacker.name, "útočí na", defender.name)

	# 1) Určení potřebného hodu na zásah
	var needed = 4
	if attacker.strenght > defender.toughness:
		needed = 3
	elif attacker.strenght < defender.toughness:
		needed = 5

	print("Útočník potřebuje hodit:", needed, "nebo více")

	# 2) Útočné hody podle attack stat
	for i in range(attacker.attack):
		var roll = randi_range(1, 6)
		print("Hod:", roll)

		if roll >= needed:
			var damage = attacker.crit if roll == 6 else attacker.hit
			print(" Zásah! Dmg:", damage)
			defender.apply_damage(damage)
		else:
			print(" Minul")

	print("Boj skončil.")
