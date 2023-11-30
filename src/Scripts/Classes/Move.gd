# Chandler Frakes

class_name Move
extends Node

# ---------------- PROPERTIES ----------------- #

@export var move_type: String
@export var move_name: String
@export var move_data: Array

# ---------------- INIT ---------------- #

func _init(move_type, move_name, move_data):
	self.move_type = move_type
	self.move_name = move_name
	self.move_data = move_data
