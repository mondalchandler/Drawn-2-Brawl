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

# ----------------------------------------- IMPORTS ------------------------------------------------ #

class_name Move
extends Node

# ---------------------------------------- CONSTANTS ------------------------------------------ #

const SPEED_REDUCTION : float = 10.0
const JUMP_REDUCTION : float = 100.0
const DASH_FORCE : float = 2.0
const HITBOX_DIST : float = 1.5

# ---------------------------------------- NODES ------------------------------------------ #

@onready var cooldown_timer : NetworkTimer = $CooldownTimer
@onready var hitbox_spawn_timer : NetworkTimer = $HitboxSpawnTimer
@onready var move_end_timer : NetworkTimer = $MoveEndTimer

# ----------------------------------------- PROPERTIES ------------------------------------------------ #

@export var move_input: String
@export var move_type: String
@export var move_name: String
@export var move_data: Array
@export var hitbox: BaseHitbox      # HOW TO ADD CUSTOM HITBOXES documentation in BaseHitbox.gd
@export var hitscan: Hitscan
@export var projectile_path: String
@export var is_chargable: bool = false

var char : RollbackCharacterController = null

var on_cooldown : bool = false
var cached_move_dir : Vector3 = Vector3.FORWARD

# ----------------------------------------- METHODS ------------------------------------------------ #

func _position_hitbox() -> void:
	self.hitbox.global_position = self.char.global_position + (self.cached_move_dir * HITBOX_DIST)


func move_ready(set_char : RollbackCharacterController) -> void:
	self.char = set_char
	self.hitbox.debug_on = true


# this function is called on every rollback network update
func move_update(input_down : bool) -> void:
	if not self.char: return
	if not input_down: return
	if input_down and self.on_cooldown: return
	if self.char.performing > 0: return
	
	self.on_cooldown = true
	self.char.performing += 1
	self.char.autorotate += 1
	self.cached_move_dir = self.char.last_nonzero_move_direction
	self._position_hitbox()
	
	cooldown_timer.start()
	hitbox_spawn_timer.start()
	move_end_timer.start()
	
	self.char.play_action_anim("pistol_whip")
	self.char.speed /= SPEED_REDUCTION
	self.char.jump_power /= JUMP_REDUCTION

# ---------------------------------------- CONNECTIONS ------------------------------------------ #

func _on_cooldown_timeout():
	self.on_cooldown = false


func _on_move_end_timer_timeout():
	self.char.speed *= SPEED_REDUCTION
	self.char.jump_power *= JUMP_REDUCTION
	self.char.performing -= 1
	self.char.autorotate -= 1
	self.hitbox.active = false


func _on_hitbox_spawn_timer_timeout():
	self.char.velocity += self.cached_move_dir * DASH_FORCE
	self._position_hitbox()
	self.hitbox.active = true

# ----------------------------------------- INIT ------------------------------------------------ #

func _init(new_move_input = "", new_move_type = "", new_move_name = "", new_move_data = [], new_hitbox = null, new_hitscan = null, new_projectile_path = ""):
	self.move_input = new_move_input
	self.move_type = new_move_type
	self.move_name = new_move_name
	self.move_data = new_move_data
	self.hitbox = new_hitbox
	self.hitscan = new_hitscan
	self.projectile_path = new_projectile_path

# ---------------------------------------- ROLLBACK FUNCTIONS ------------------------------------------ #

func _network_process(_input: Dictionary) -> void:
	pass

func _save_state() -> Dictionary:
	return {
		on_cooldown = self.on_cooldown,
		cached_move_dir = self.cached_move_dir
	}

func _load_state(state: Dictionary) -> void:
	self.on_cooldown = state["on_cooldown"]
	self.cached_move_dir = state["cached_move_dir"]
