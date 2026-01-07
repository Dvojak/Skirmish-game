extends Node2D
class_name TurnManager

@onready var attack_overlay: TileMapLayer = get_node("../AttackOverlay/TileMapLayer")
@onready var overlay_map: TileMapLayer = get_node("../MovementOverlay/TileMapLayer")
@onready var tile_map: TileMapLayer = get_node_or_null("../TileMap/TileMapLayer")
@onready var units_container = get_node("../Unit")
@onready var blue: Player = get_node("../BluePlayer")
@onready var red: Player = get_node("../RedPlayer")
@onready var popup = get_node("../CanvasLayer/UnitStatPopup")
@onready var initiative_ui = get_node("../CanvasLayer/Initiative")
@onready var turn_label: Label = get_node("../CanvasLayer/Initiative/Winner")
@onready var dice_label: Label = get_node("../CanvasLayer/Initiative/DicePanel/DiceLabel")
@onready var current_label: Label = get_node("../CanvasLayer/TurnIndicator/TurnLabel")






const DISENGAGE_RANGE := 3
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
	
	for cell in tile_map.get_used_cells():
		var tile_data = tile_map.get_cell_tile_data(cell)
		var walkable = tile_data and tile_data.get_custom_data("Walkable")
		astar_grid.set_point_solid(cell, not walkable)

	position = tile_map.map_to_local(tile_map.local_to_map(global_position))
	
	players = [blue, red]

	for u in units_container.get_children():
		if u is Unit:
			if "_P1" in u.name:
				u.oowner = blue
				blue.units.append(u)
			elif "_P2" in u.name:
				u.oowner = red
				red.units.append(u)
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
	print("Začíná nové kolo")
	roll_initiative() 
	start_turn()


func start_turn():
	var current_player = players[numc_player]
	current_label.text = current_player.name
	current_label.show()
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
			print("Vybral jsi jednotku:", u.type)

			overlay_map.clear()
			attack_overlay.clear()

			if u.is_engaged(tile_map, units_container):
				print("⚔️ Jednotka je engaged → disengage overlay")
				show_disengage_range(u)
				show_attack_range(u)
			else:
				show_movement_range(u)
				show_attack_range(u)

	elif event.is_action_pressed("move") and selected_unit:

	# 1️⃣ NEJDŘÍV zkus útok
		var clicked_unit = _get_unit_under_mouse()
		if clicked_unit and clicked_unit != selected_unit:
			print("Klikl jsi na jednotku → pokusím se zaútočit")
			try_attack(selected_unit, clicked_unit)
			return

	# 2️⃣ TEPRVE POTOM řeš pohyb / disengage
		

	# 3️⃣ Normální pohyb
		var target_tile = _get_tile_under_mouse()
		var start = tile_map.local_to_map(selected_unit.global_position)
		var end = tile_map.local_to_map(target_tile)

		var path = astar_grid.get_id_path(start, end).slice(1)
		if path.is_empty():
			print("Žádná cesta nebyla nalezena")
			return
		if selected_unit.is_engaged(tile_map, units_container):
			if path.size() > DISENGAGE_RANGE:
				path = path.slice(0, DISENGAGE_RANGE)

		elif path.size() > selected_unit.movement_points:
			path = path.slice(0, selected_unit.movement_points)

		var world_path: Array[Vector2] = []
		for p in path:
			world_path.append(tile_map.map_to_local(p))

		selected_unit.move_along_path(world_path)
		
	elif event.is_action_pressed("wait") and selected_unit :
		skip_unit_action()
		return

func roll_initiative():
	for p in players:
		p.roll_initiative_dice()

	var singles_p1 = _count_singles(players[0].dice_pool)
	var singles_p2 = _count_singles(players[1].dice_pool)

	var winner_index := -1

	if singles_p1 == singles_p2:
		print("Remíza, hází se znovu.")
		roll_initiative()
		return
	else:
		winner_index = 0 if singles_p1 > singles_p2 else 1

	initiative_ui.show_dice(players[0].dice_pool, players[1].dice_pool, players[winner_index].name)

	print("*** Začíná hráč:", players[winner_index].name, "***")
	numc_player = winner_index




func _count_singles(dice: Array[int]) -> int:
	var occurrences := {}
	for d in dice:
		occurrences[d] = occurrences.get(d, 0) + 1

	var singles = 0
	for key in occurrences.keys():
		if occurrences[key] == 1:
			singles += 1

	return singles


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
			if abs(x) + abs(y) > unit.far:
				continue

			var target = start + Vector2i(x, y)

			if target == start:
				continue

			if not tile_map.get_used_rect().has_point(target):
				continue

			var tile_data := tile_map.get_cell_tile_data(target)
			if tile_data == null:
				continue

			if not tile_data.get_custom_data("Walkable"):
				continue

			if not has_line_of_sight_tile(start, target):
				continue

			attack_overlay.set_cell(target, 0, Vector2i.ZERO)

func show_disengage_range(unit: Unit):
	overlay_map.clear()

	var start = tile_map.local_to_map(unit.global_position)
	var reachable = get_reachable_tiles(start, DISENGAGE_RANGE)

	for tile in reachable:
		overlay_map.set_cell(tile, 0, Vector2i.ZERO)



func get_reachable_tiles(start: Vector2i, movement: int) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var frontier: Array[Vector2i] = [start]
	var visited: = { start: 0 }

	while frontier.size() > 0:
		var current: Vector2i = frontier.pop_front()
		var current_cost: int = visited[current]

		if current != start:
			reachable.append(current)

		if current_cost >= movement:
			continue

		var dirs = [
			Vector2i(1, 0),
			Vector2i(-1, 0),
			Vector2i(0, 1),
			Vector2i(0, -1)
		]

		for dir in dirs:
			var next = current + dir

			if visited.has(next):
				continue

			if not tile_map.get_used_rect().has_point(next):
				continue

			var tile_data = tile_map.get_cell_tile_data(next)

			if tile_data == null:
				continue

			if not tile_data.get_custom_data("Walkable"):
				continue
				
			visited[next] = current_cost + 1
			frontier.append(next)

	return reachable
	
	
func has_line_of_sight_tile(start: Vector2i, end: Vector2i) -> bool:
	var x0 = start.x
	var y0 = start.y
	var x1 = end.x
	var y1 = end.y

	var dx = abs(x1 - x0)
	var sx = 1 if x0 < x1 else -1
	var dy = -abs(y1 - y0)
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy

	while true:
		
		if not (x0 == start.x and y0 == start.y) and not (x0 == end.x and y0 == end.y):
			var tile = Vector2i(x0, y0)
			var tile_data = tile_map.get_cell_tile_data(tile)
			if tile_data and not tile_data.get_custom_data("Walkable"):
				return false

		if x0 == x1 and y0 == y1:
			break

		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

	return true

	
func try_attack(attacker: Unit, defender: Unit):
	if attacker.actions <= 0:
		print("Jednotka už nemá akce.")
		return

	var start = tile_map.local_to_map(attacker.global_position)
	var target = tile_map.local_to_map(defender.global_position)

	if abs(start.x - target.x) + abs(start.y - target.y) > attacker.far:
		print("Cíl je mimo dosah útoku.")
		return
	
	if not has_line_of_sight_tile(start, target):
		print("Útok zablokován překážkou — není line of sight.")
		return

	start_combat(attacker, defender)
	attacker.actions -= 1
	print("Akce zbývající:", attacker.actions)

	if attacker.actions <= 0:
		_on_finished_action()


func start_combat(attacker: Unit, defender: Unit):
	print(" Boj začíná:", attacker.name, "útočí na", defender.name)


	var needed = 4
	if attacker.strenght > defender.toughness:
		needed = 3
	elif attacker.strenght < defender.toughness:
		needed = 5

	print("Útočník potřebuje hodit:", needed, "nebo více")


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
	
func skip_unit_action():
	if selected_unit.actions <= 0:
		return

	print(" Skip akce jednotky:", selected_unit.name)

	# spotřebuj jednu akci
	selected_unit.actions -= 1

	# uklid overlaye
	overlay_map.clear()
	attack_overlay.clear()

	# zruš výběr (důležité!)
	selected_unit = null



	# pokud jednotka nemá žádné akce, vyřeší se konec tahu
	if selected_unit == null:
		_on_finished_action()


	



	
