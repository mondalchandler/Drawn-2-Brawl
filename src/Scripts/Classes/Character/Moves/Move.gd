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

@export var SPEED_REDUCTION : float = 10.0
@export var JUMP_REDUCTION : float = 100.0
@export var DASH_FORCE : float = 2.0
@export var HITBOX_DIST : float = 1.5

# ---------------------------------------- NODES ------------------------------------------ #

@export var cooldown_timer : NetworkTimer = null
@export var hitbox_spawn_timer : NetworkTimer = null
@export var move_end_timer : NetworkTimer = null

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


func move_ready(set_char : RollbackCharacterController, debug_on : bool) -> void:
	self.char = set_char
	if hitbox: self.hitbox.debug_on = debug_on


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
	if hitbox: self._position_hitbox()
	
	cooldown_timer.start()
	# spawn multiple projectiles for successive firing
	if self.move_type == "PROJECTILE":
		for i in range(self.move_data[0]):
			var temp_timer : NetworkTimer = NetworkTimer.new()
			temp_timer.one_shot = true
			temp_timer.wait_ticks = int(self.move_data[1][i-1] * 30)
			print(self.move_data[1][i-1] * 30)
			self.get_parent().add_child(temp_timer)
			temp_timer.connect("timeout", self._on_hitbox_spawn_timer_timeout)
			temp_timer.start()
	else:
		hitbox_spawn_timer.start()
	move_end_timer.start()
	
	self.char.can_move = false
	self.char.play_action_anim(self.move_input)
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
	if hitbox: self.hitbox.active = false
	self.char.can_move = true


func _on_hitbox_spawn_timer_timeout():
	if self.move_type == "PROJECTILE":
		var PROJECTILE: PackedScene = load(self.projectile_path)
		if PROJECTILE:
			var projectile = PROJECTILE.instantiate()
			self.char.get_parent().get_parent().add_child(projectile)
			projectile.global_position = self.char.global_position
			projectile.owner_char = self.char
			# TODO: Create timer for spawning multiple projectiles
			#await get_tree().create_timer(self.move_data[1][i-1]).timeout
			projectile.emit()
	else:
		self.char.velocity += self.cached_move_dir * DASH_FORCE
		if hitbox:
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
