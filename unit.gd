
extends Node

var activated = false

func reset_activation():
	activated = false

func activate():
	if activated:
		return
	print("Jednotka ", name, " je aktivována!")
	activated = true
