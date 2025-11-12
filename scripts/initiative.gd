extends Control

func show_dice(p1_dice: Array[int], p2_dice: Array[int], winner_name: String):
	# Vyčisti staré labely
	for child in get_children():
		child.queue_free()

	# Vytvoř nové labely
	var p1_label = Label.new()
	p1_label.text = "Player 1 Dice: " + str(p1_dice)
	add_child(p1_label)

	var p2_label = Label.new()
	p2_label.text = "Player 2 Dice: " + str(p2_dice)
	add_child(p2_label)

	var winner_label = Label.new()
	winner_label.text = "Winner: " + winner_name
	add_child(winner_label)

	# Umístění (můžeš upravit)
	p1_label.position = Vector2(20, 20)
	p2_label.position = Vector2(20, 50)
	winner_label.position = Vector2(20, 80)

	# Fade animace
	modulate.a = 0.0
	show()

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4) # fade-in
	tween.chain().tween_property(self, "modulate:a", 0.0, 1.0) # fade-out
