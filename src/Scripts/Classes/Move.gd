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

# How MOVE DATA is structured for each move type:
	# MELEE (i.e. Regular Hitbox):  [dmg, hitstun, kb_length, kb_stg, hitbox_size]
	# HITSCAN (TODO):               [dmg, hitstun, kb_stg]

class_name Move
extends Node

# ---------------- PROPERTIES ----------------- #

@export var move_input: String
@export var move_type: String
@export var move_name: String
@export var move_data: Array
@export var hitbox: BaseHitbox      # HOW TO ADD CUSTOM HITBOXES documentation in BaseHitbox.gd
@export var hitscan: Hitscan
@export var projectile_path: String
@export var is_chargable: bool = false

var move_ended = false


func move_charge_effect(delta):
	pass
	
func move_reset():
	pass

# ---------------- INIT ---------------- #

func _init(move_input = "", move_type = "", move_name = "", move_data = [], hitbox = null, hitscan = null, projectile_path = ""):
	self.move_input = move_input
	self.move_type = move_type
	self.move_name = move_name
	self.move_data = move_data
	self.hitbox = hitbox
	self.hitscan = hitscan
	self.projectile_path = projectile_path
