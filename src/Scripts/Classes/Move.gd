# Chandler Frakes

# Moves are the basic building blocks of combat in the game. They will be instantiated
# whenever a player presses an attack button, and are then passed to the combat system
# which handles the rest of the logic.

# A move is defined using the following format:
# [
#	MOVE NAME: String,
#	MOVE TYPE: String,
#	MOVE DATA: Array (see below for format of each type)
# ]

# HOW MOVE DATA IS STRUCTURED FOR EACH TYPE
# MELEE (i.e. Regular Hitbox):	[offset, dmg, hitstun, kb_length, kb_stg, hitbox_size]
# HITSCAN (TODO):				[dmg, hitstun, kb_stg]

class_name Move
extends Node

# ---------------- PROPERTIES ----------------- #

@export var move_input: String
@export var move_type: String
@export var move_name: String
@export var move_data: Array

# ---------------- INIT ---------------- #

func _init(move_input = "", move_type = "", move_name = "", move_data = []):
	self.move_input = move_input
	self.move_type = move_type
	self.move_name = move_name
	self.move_data = move_data
