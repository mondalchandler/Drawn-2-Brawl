# Chandler Frakes, Kyle Senebouttarath, Alex Ottelien

# --------------------------------------- IMPORTS ------------------------------------------- #

class_name RollbackCharacterController 
extends CharacterBody3D

# ---------------------------------------- CONSTANTS ------------------------------------------ #

const FLASH_DELAY: float = 0.125

const BLOCK_STAMINA_AMOUNT : float = 10
const BLOCK_RECHARGE_TIME : float = 4
const PERFECT_BLOCK_TIME_TOTAL : float = 0.25

const TARGET_ARROW_DEFAULT_SIZE: float = 0.0002

const MOVE_MAP_NAMES = [
	"ground_nc", "ground_nf", "ground_sc", "ground_sf", 
	"air_nc", "air_nf", "air_sc", "air_sf"
]

# --------------------------------------- PROPERTIES ------------------------------------------- #

# inherited properties from CharacterBody3D: 
	# position : Vector3
	# velocity : Vector3

# base character settings
@export var display_name: String = "TestCharacter"
@export var health: float = 100
@export var max_health: float = 100

# core movement settings
@export var speed: float = 5.0
@export var air_speed: float = 5.0
@export var jump_power: float = 15
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") + 15

# enum for core movement state management
enum PlayerState { IDLE, RUNNING, JUMPING, FALLING, KNOCKBACK, BLOCKING }

# boolean flips for special states
@export var targetting : bool = false
@export var blocking : bool = false
@export var invincible : bool = false
@export var perfect_blocking : bool = false
@export var grabbing : bool = false
@export var dodging : bool = false
@export var can_move : bool = true

# various dynamic and quick updating properties for state and physics
var move_direction : Vector3 = Vector3.ZERO
var knockback : Vector3 = Vector3.ZERO
var anim_speed_scale: float = 1.0

# variables used to track our player's status with blocking abilities
var block_stamina : float = BLOCK_STAMINA_AMOUNT
var perfect_block_time : float = PERFECT_BLOCK_TIME_TOTAL
var temp_block_recharge_time : float = 4.0

# variables used to track who our character is currently targetting and grabbing
var z_target: Node3D = null
var grab_target: Node3D = null

# used to show the floor indicator
@export var floor_indicator_enabled: bool = true

# determines if our inputs should affect our character 
@export var can_input: bool = true

# private variable to show our debug UI
var _show_debug_info: bool = false

# variables used to track the moves currently loaded onto our character
@export var ground_nc: Move = null
@export var ground_nf: Move = null
@export var ground_sc: Move = null
@export var ground_sf: Move = null
@export var air_nc: Move = null
@export var air_nf: Move = null
@export var air_sc: Move = null
@export var air_sf: Move = null

# --------------------------------------- PRIVATE PROPERTIES ------------------------------------------- #

var _old_health: float = health
var _state: PlayerState = PlayerState.IDLE
var _flashing_time: float = 0.0
var _flashing_switch_time: float = 0.0
var _input_state_text: String = ""
var _move_controller = null

# --------------------------------------- SELF NODES ------------------------------------------- #

@onready var hurtbox: CollisionShape3D = $Hurtbox
@onready var sprite: Sprite3D = $CharacterSprite

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_tree_state_machine = anim_tree.get("parameters/playback")

@onready var floor_ring: Decal = $FloorRing
@onready var floor_shadow: Decal = $FloorShadow
@onready var floor_raycast: RayCast3D = $FloorRaycast

@onready var player_nametag: Sprite3D = $PlayerNametag
@onready var debug_tag: Sprite3D = $DebugInfo

@onready var current_cam: Camera3D = get_viewport().get_camera_3d()

@onready var target_arrow: Sprite3D = $TargetArrow

@onready var stamina_bar = $StaminaBar3D

# --------------------------------------- GLOBAL NODES ------------------------------------------- #

@onready var main_scene = get_tree().root.get_node("main_scene")
@onready var players = main_scene.get_node("Players")

## ------------------------------------------- SIGNALS --------------------------------------------- #

signal died
signal health_changed

# --------------------------------------- INPUT FUNCTIONS ------------------------------------------- #

func _get_camera_relative_input(input : Vector3) -> Vector3:
	if not self.current_cam: 
		return input

	var cam_right = self.current_cam.global_transform.basis.x
	var cam_forward = self.current_cam.global_transform.basis.z
	
	# make cam_forward horizontal:
	cam_forward = cam_forward.slide(Vector3.UP).normalized()
	
	# return camera relative input vector:
	return cam_forward * input.z + cam_right * input.x


func _handle_directional_input(total_input : Dictionary) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.z = Input.get_axis("move_forward", "move_back")
	
	# update the input based on our perspective with our player camera
	# this is done client sided because players could have their own unique camera angles
	input_dir = self._get_camera_relative_input(input_dir)
	
	# store the user's directional input
	total_input["input_vector"] = input_dir


func _handle_jump_input(total_input : Dictionary) -> void:
	if Input.is_action_just_pressed("jump"):
		total_input["pressed_jump"] = true


func _handle_target_input(total_input : Dictionary) -> void:
	if Input.is_action_just_pressed("z_target"):
		total_input["pressed_target"] = true


func _handle_block_input(total_input : Dictionary) -> void:
	if Input.is_action_pressed("block"):
		total_input["holding_block"] = true
	else:
		total_input["holding_block"] = false


# --------------------------------------- PHYSICS PROCESS FUNCTIONS ------------------------------------------- #

# inherited functions from CharacterBody3D
	# is_on_floor() -> bool
	# move_and_slide()

# -- update the velocities of the character and then apply them
func _update_movement() -> void:
	
	# we're using this because this is the length of one frame in seconeds. we can't use dt because it doesn't exist for rollback
	var delta = (1.0 / 60.0)
	
	if !self.blocking:
		if is_on_floor():
			if move_direction.length() > 0.0:
				self._state = PlayerState.RUNNING
				velocity.x = move_direction.x * self.speed + knockback.x
				velocity.z = move_direction.z * self.speed + knockback.z

				# if player is moving left, flip the sprite
				sprite.flip_h = (move_direction.x < 0)
			else:
				self._state = PlayerState.IDLE

				#TODO: Lowkey feels weird and could be better
				velocity.x = lerp(velocity.x, 0.0, delta * 7.0) + knockback.x
				velocity.z = lerp(velocity.z, 0.0, delta * 7.0) + knockback.z
		else:
			velocity.x = lerp(velocity.x, move_direction.x * self.air_speed, delta * 3.0)
			velocity.z = lerp(velocity.z, move_direction.z * self.air_speed, delta * 3.0)
			if velocity.y > 0.0:
				self._state = PlayerState.JUMPING
			else:
				self._state = PlayerState.FALLING
	else:
		if !is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, delta * 3.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 3.0)
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0) + knockback.x
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0) + knockback.z
	
	if !self.can_move:
		velocity = knockback
	
	move_and_slide()


func _update_block(is_holding_input : bool) -> void:
	if is_holding_input and block_stamina > 0:
		self.blocking = true
		self._state = PlayerState.BLOCKING
		self.temp_block_recharge_time = 0.0
		self.perfect_blocking = true
	
	if self.blocking:
		if not is_holding_input or block_stamina <= 0:
			self.blocking = false
			self._state = PlayerState.IDLE
			self.perfect_blocking = false
			self.perfect_block_time = self.PERFECT_BLOCK_TIME_TOTAL


# --------------------------------------- VARIOUS PROCESS FUNCTIONS ------------------------------------------- #

func _handle_recieved_input(total_input : Dictionary) -> void:
	# get our movement variables and update how we move
	self.move_direction = total_input.get("input_vector", Vector3.ZERO)
	self._update_movement()
	
	# get our blocking input and determine if we can be in the blocking state
	var is_holding_block_input = total_input.get("holding_block", false)
	self._update_block(is_holding_block_input)
	
	# update our targetting state
	var pressed_target = total_input.get("pressed_target", false)
	if pressed_target:
		self.targetting = not self.targetting
	
	# add jumping physics
	var pressed_jump = total_input.get("pressed_jump", false)
	if is_on_floor() and pressed_jump and !self.blocking:
		velocity.y += jump_power


# -- given the current state of the player, update the animation tree
func _update_core_animations() -> void:
	if self._state == PlayerState.IDLE:
		self.anim_tree_state_machine.travel("idle")
	elif self._state == PlayerState.RUNNING:
		self.anim_tree_state_machine.travel("run")
	elif self._state == PlayerState.JUMPING:
		self.anim_tree_state_machine.travel("jump")
	elif self._state == PlayerState.FALLING:
		self.anim_tree_state_machine.travel("jump")
	elif self._state == PlayerState.BLOCKING:
		self.anim_tree_state_machine.travel("block")


# -- checks if the player health has changed; if so, send a signal
func _update_health_change() -> void:
	if self.health != self._old_health:
		emit_signal("health_changed", self.health, self._old_health)
		self._old_health = self.health


# -- updates the positions of the floor indicators
func _update_floor_indicator() -> void:
	if floor_raycast.is_colliding():
		var floor_pos = floor_raycast.get_collision_point()
		var floor_norm = floor_raycast.get_collision_normal()
		floor_ring.global_position = floor_pos
		floor_ring.global_rotation = floor_norm
		floor_shadow.global_position = floor_pos
		floor_shadow.global_rotation = floor_norm
	
	if is_on_floor():
		floor_ring.set_meta("goal_albedo_mix", 0.0)
	else:
		floor_ring.set_meta("goal_albedo_mix", 1.0)
	
	floor_ring.albedo_mix = lerp(floor_ring.albedo_mix, floor_ring.get_meta("goal_albedo_mix"), 12 * (0.016667))


# -- function that iterates through a player list and returns the one closest to self
# -- author: Kyle Senebouttarath
func _get_closest_player() -> Node3D:
	
	# track the closet player and their distance
	var closest_target: Node3D = null
	var closest_distance: float = INF
	
	# iterate through the players
	for player in players.get_children():
		
		# if the player we check isn't ourself and they're alive
		if player != self and player.health > 0:
			
			# calc their dist. if it's closer than our current closest target, replace it to be our new closest
			var dist: float = (self.global_position - player.global_position).length()
			if dist <= closest_distance:
				closest_distance = dist
				closest_target = player
	
	# return the closet player
	return closest_target


# -- updates the z target if targetting is enabled
func _update_z_target() -> void:
	
	# if we're targetting, get the closest player as our target
	if self.targetting:
		self.z_target = self._get_closest_player()
	else:
		self.z_target = null
	
	# update our target arrow visibility and position
	if self.z_target:
		target_arrow.global_position = self.z_target.global_position + Vector3(0, self.z_target.global_transform.basis.y.length() * 1.5, 0)
		target_arrow.show()
	else:
		target_arrow.hide()
	
	# this makes the arrow pulse/"breath" by using a sine wave
	target_arrow.pixel_size = TARGET_ARROW_DEFAULT_SIZE + sin(Time.get_ticks_msec() * 0.0125) * 0.000015


# -- updates the 3d text for debug information. append more information if need be
func _update_debug_text() -> void:
	self.debug_tag.global_position = self.global_position + Vector3(0, 1, 0)
	if self.current_cam:
		self.debug_tag.global_position += self.current_cam.global_transform.basis.x * 2
	self.debug_tag.visible = _show_debug_info
	self.debug_tag.text = "PlayerState: " + PlayerState.keys()[_state] 
	self.debug_tag.text += "\nAnimationNode: " + anim_tree_state_machine.get_current_node()
	self.debug_tag.text += "\nTargetting: " + str(targetting)
	self.debug_tag.text += "\nTarget: " + str(z_target)
	self.debug_tag.text += "\n" + _input_state_text


# -- updates player flashing. used for invincibility
func _update_invincible_flash(dt: float) -> void:
	if _flashing_time > 0.0:
		_flashing_switch_time += dt
		if _flashing_switch_time >= FLASH_DELAY:
			if sprite.visible:
				sprite.hide()
			else:
				sprite.show()
			_flashing_switch_time = 0.0
		_flashing_time -= dt
	else:
		_flashing_time = 0.0
		_flashing_switch_time = 0.0
		sprite.show()


func _update_block_recharge_delay(delta):
	if not self.blocking:
		if self.temp_block_recharge_time < BLOCK_RECHARGE_TIME:
			self.temp_block_recharge_time+=delta
			if self.temp_block_recharge_time > BLOCK_RECHARGE_TIME:
				self.temp_block_recharge_time = BLOCK_RECHARGE_TIME
		elif self.block_stamina < BLOCK_STAMINA_AMOUNT:
			self.block_stamina+=delta
			if self.block_stamina >= BLOCK_STAMINA_AMOUNT:
				self.block_stamina = BLOCK_STAMINA_AMOUNT
				if(stamina_bar):
					stamina_bar.visible = false
	else:	
		if perfect_block_time > 0:
			perfect_block_time -= delta
		else:
			perfect_blocking = false
		self.block_stamina-=delta
		if(stamina_bar):
			stamina_bar.visible = true

	if(stamina_bar):
		stamina_bar.update_stamina_bar(block_stamina*10)

# --------------------------------------- ROLLBACK FUNCTIONS ------------------------------------------- #

# this is a special virtual method that will get called by SyncManager
# this is because this node is part of the "network_sync" group
func _get_local_input() -> Dictionary:
	
	# track all of our player inputs in a dictionary
	var total_input := {}
	
	# gather all of our input sources
	if self.can_input:
		self._handle_directional_input(total_input)
		self._handle_jump_input(total_input)
		self._handle_target_input(total_input)
		self._handle_block_input(total_input)
	
	# return all of our player's input
	return total_input


# custom code used to predict what the player's input may be if there is a rollback
# the better we can predict the player, the smaller the network artifacts
func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	
	# clone new dictionary for the input
	var predicted_input = previous_input.duplicate()
	
	# it's very unlikely we will get two of these inputs in a row, so we can throw out these values
	# for example, full pressed space twice in 2 frames,
	predicted_input.erase("pressed_jump")
	predicted_input.erase("pressed_target")
	
	# return new prediction
	return predicted_input
	
# this is essentially the "_process" method for this node, but with network sychronization
# NOTE: this is run on every TICK, not every FRAME
func _network_process(input: Dictionary) -> void:
	
	# TODO: this should probably be changed to be something else
#	if event.is_action_pressed("pause"):
#		pause_menu_layer.toggle()
#	if pause_menu_layer.is_open():
#		return
	
	var delta = (0.0166667)
	
	# do work based on the input we've recieved
	self._handle_recieved_input(input)
	
	# handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# update animations
	self.anim_tree.advance(delta * anim_speed_scale)
	self._update_core_animations()

	# do other misc updates
	self._update_floor_indicator()
	self._update_z_target()
	self._update_debug_text()
	self._update_health_change()
	
	# these probably shouldn't use delta anymore?
	self._update_invincible_flash(delta)
	self._update_block_recharge_delay(delta)
	
	# update display name (in case it gets changed mid playtime)
	self.player_nametag.text = self.display_name
	
	# we've ended our process changes
	return


# called at the end of every tick
func _save_state() -> Dictionary:
	return {
		position = self.position,
		velocity = self.velocity,
		state = self._state,
		health = self.health,
		targetting = self.targetting,
		blocking = self.blocking,
		knockback = self.knockback,
	}


# called whenever a rollback is neccessary; applies state to our current scene
func _load_state(state: Dictionary) -> void:
	self.position = state["position"]
	self.velocity = state["velocity"]
	self._state = state["state"]
	self.health = state["health"]
	self.targetting = state["targetting"]
	self.blocking = state["blocking"]
	self.knockback = state["knockback"]


# ---------------------------------------- PUBLIC FUNCTIONS ------------------------------------------------- #

# -- heals the player to full. should be used on the server only!
func full_heal() -> void:
	health = max_health

# -- returns if health is greater than zero. can be used on both client and server
func is_alive() -> bool:
	return health > 0.0


func perform_invincible_frame_flashing(time_length: float) -> void:
	_flashing_time = time_length


# -- sets the current camera object. should be used on the client only!
func set_camera(cam: Camera3D) -> void:
	self.current_cam = cam


# -- makes the character take damage. should be used on the server only!
func take_damage(damage: float) -> void:
	if !self.blocking:
		self.health -= damage
		if self.health <= 0:
			self.health = 0
			emit_signal("died")


# ---------------------------------------- INIT AND CONNECTIONS ------------------------------------------------- #


# -- constructor
func _init() -> void:
	pass


# -- called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim_tree_state_machine.start("idle")
	#_move_controller = MoveController.new(self, $AnimationTree, $CharacterSprite, $Hurtbox)
	#add_child(_move_controller)

# ---------------------------------------- END OF SCRIPT ------------------------------------------------- #



##	if event.as_text()
#
#	# move inputs
#
#	_move_controller.action(event)
#	if event.is_pressed():
#		_input_state_text = ""
#
#		# TODO: MoveController requires that the move animation name be in the MOVE_MAP_NAMES array
#		#		in order to spawn the hitbox correctly. This required creating 4 extra states
#		#		since each input has 2 outcomes (1 for on ground, 1 for in air). As a result, the
#		#		input will not match with what move is actually being output in the debugger text.
#		for name in MOVE_MAP_NAMES:
#			_input_state_text += "\n" + name + ": " + str(event.is_action_pressed(name))
#

## ---------------- PRIVATE FUNCTIONS ---------------- #

## -- converts the move name to the type for the move controller
## -- NOT FULLY IMPLEMENTED DUE TO LACK OF MOVES
#func _move_name_to_type(name):
#	if name == "ground_nc":
#		return ""
#	if name == "ground_nf":
#		return ""
#	if name == "ground_sc":
#		return ""
#	if name == "ground_sf":
#		return ""
#	if name == "air_nc":
#		return ""
#	if name == "air_nf":
#		return ""
#	if name == "air_sc":
#		return ""
#	if name == "air_sf":
#		return ""


## TODO: When provided a desination vector, move the player to said direction
#func move_to(destination: Vector3) -> void:
#	pass

# ----------------  MAIN FUNCTIONS ---------------- #
#
## -- called when the user inputs anything  
#func _input(event : InputEvent) -> void:
#
#	if not can_player_input:
#		return
#
#	if event.is_action_pressed("pause"):
#		pause_menu_layer.toggle()
#
#	if pause_menu_layer.is_open():
#		return
#
#
##	if event.as_text()
#
#	# move inputs
#
#	_move_controller.action(event)
#	if event.is_pressed():
#		_input_state_text = ""
#
#		# TODO: MoveController requires that the move animation name be in the MOVE_MAP_NAMES array
#		#		in order to spawn the hitbox correctly. This required creating 4 extra states
#		#		since each input has 2 outcomes (1 for on ground, 1 for in air). As a result, the
#		#		input will not match with what move is actually being output in the debugger text.
#		for name in MOVE_MAP_NAMES:
#			_input_state_text += "\n" + name + ": " + str(event.is_action_pressed(name))
