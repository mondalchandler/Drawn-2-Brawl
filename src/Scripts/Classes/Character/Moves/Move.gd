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


func move_charge_effect(_delta):
	pass
	
func move_reset():
	pass

# ---------------- INIT ---------------- #

func _init(new_move_input = "", new_move_type = "", new_move_name = "", new_move_data = [], new_hitbox = null, new_hitscan = null, new_projectile_path = ""):
	self.move_input = new_move_input
	self.move_type = new_move_type
	self.move_name = new_move_name
	self.move_data = new_move_data
	self.hitbox = new_hitbox
	self.hitscan = new_hitscan
	self.projectile_path = new_projectile_path
