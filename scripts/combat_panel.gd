extends Control

@onready var attacker_sprite: TextureRect = get_node("AttackBox/TextureRect")
@onready var attacker_label: Label = get_node("AttackBox/Label")
@onready var defender_sprite: TextureRect = get_node("DefenderBox/TextureRect")
@onready var defender_label: Label = get_node("DefenderBox/Label")
@onready var logc: RichTextLabel = get_node("CenterBox/RichTextLabel")

var attacker: Unit
var defender: Unit
var combat_finished := false


func start_combat(a: Unit, d: Unit) -> void:
	attacker = a
	defender = d
	combat_finished = false

	# UI init
	attacker_label.text = "%s (HP: %d)" % [attacker.name, attacker.health_points]
	defender_label.text = "%s (HP: %d)" % [defender.name, defender.health_points]

	logc.clear()
	logc.append_text("[b]Boj začíná![/b]\n")

	attacker_sprite.texture = attacker.get_sprite_texture()
	defender_sprite.texture = defender.get_sprite_texture()

	# Sleduj smrt obránce
	if not defender.died.is_connected(_on_defender_died):
		defender.died.connect(_on_defender_died)

	show()
	run_combat()


func run_combat() -> void:
	var needed := 4
	if attacker.strenght > defender.toughness:
		needed = 3
	elif attacker.strenght < defender.toughness:
		needed = 5

	logc.append_text("Útočník potřebuje %d+\n\n" % needed)

	for i in range(attacker.attack):
		if combat_finished:
			return

		await get_tree().create_timer(0.6).timeout

		var roll := randi_range(1, 6)
		logc.append_text("Hod: %d → " % roll)

		if roll >= needed:
			var dmg := attacker.crit if roll == 6 else attacker.hit
			defender.apply_damage(dmg)

			if roll == 6:
				logc.append_text("[color=red]CRIT! %d dmg[/color]\n" % dmg)
			else:
				logc.append_text("[color=orange]Zásah %d dmg[/color]\n" % dmg)

			if combat_finished:
				return
		else:
			logc.append_text("[color=gray]Minul[/color]\n")

		if is_instance_valid(defender):
			defender_label.text = "%s (HP: %d)" % [
				defender.name,
				defender.health_points
			]

	await get_tree().create_timer(1.0).timeout
	end_combat()


func _on_defender_died(unit: Unit) -> void:
	combat_finished = true

	logc.append_text(
		"\n[color=red][b]%s padl![/b][/color]\n" % unit.name
	)

	await get_tree().create_timer(0.6).timeout
	unit.queue_free()
	end_combat()


func end_combat() -> void:
	logc.append_text("\n[b]Boj skončil[/b]\n")
	await get_tree().create_timer(1.0).timeout
	hide()
