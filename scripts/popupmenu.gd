extends PopupPanel

@onready var image = $TextureRect
@onready var health_label = $VBoxContainer/Health
@onready var toughness_label = $VBoxContainer/Toughness
@onready var movement_label = $VBoxContainer/Movement
@onready var attack_label = $VBoxContainer/Attack
@onready var strenght_label = $VBoxContainer/Strenght
@onready var far_label = $VBoxContainer/Far
@onready var hit_label = $VBoxContainer/Hit
@onready var crit_label = $VBoxContainer/Crit

func _ready():
	self.visible = false


func show_stats(unit):
	health_label.text = "HP: %s" % unit.health_points
	toughness_label.text = "Armor: %s" % unit.toughness
	movement_label.text = "Movement: %s" % unit.movement_points
	strenght_label.text = "Strenght: %s" % unit.strenght
	attack_label.text = "Attack: %s" % unit.attack
	far_label.text = "Far: %s" % unit.far
	hit_label.text = "Hit: %s" % unit.hit
	crit_label.text = "Crit: %s" % unit.crit
	
	# Pokud máš obrázek ve unit

	popup_centered()  # Zobrazí popup uprostřed

	self.visible = true
	

	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.2)  # fade-in animace

func hide_card():
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.2)
	await t.finished
	self.visible = false
