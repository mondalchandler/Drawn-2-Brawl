# Chandler Frakes, Kyle Senebouttarath, Alex Ottelien

# --------------------------------------- IMPORTS ------------------------------------------- #

class_name RollbackCharacterController 
extends CharacterBody3D

# ---------------------------------------- CONSTANTS ------------------------------------------ #

#so, if you pass 45 as limit, avoid numerical precision errors when angle is 45.
const FLOOR_ANGLE_THRESHOLD : float = 0.01

const FLASH_DELAY: float = 0.125

const MAX_STAMINIA_TICKS : int = 600				# at 60 ticks a second, this is 10 seconds
const BLOCKING_STAMINA_USAGE_PER_TICK : int = 1		# how much stamina is used per tick when blocking
const STAMINA_RECHARGE_PER_TICK : int = 2			# how much stamina is recharged per tick
const STAMINIA_RECHARGE_COOLDOWN : int  = 240		# cooldown before stamina beings recharging after it is used

const ROLL_VELOCITY : int = 10
const ROLL_COST : int = MAX_STAMINIA_TICKS / 4

const TARGET_ARROW_DEFAULT_SIZE: float = 0.0002

# private variable to show our debug UI
const SHOW_DEBUG_INFO: bool = true

const INPUT_MOVE_NAMES = [
	"normal_close", "normal_far",
	"special_close", "special_far"
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
@export var dodging : bool = false
@export var can_move : bool = true

# various dynamic and quick updating properties for state and physics
var move_direction : Vector3 = Vector3.ZERO
var knockback : Vector3 = Vector3.ZERO
var kb_x : float = 0.0
var kb_y : float = 0.0
var kb_z : float = 0.0
var anim_speed_scale: float = 1.0
var sprite_flipped: bool = false

# variables used to track our player's status with blocking and rolling abilities
var stamina : int = MAX_STAMINIA_TICKS
var stamina_recharge_cooldown : int = 0

# variables used to track who our character is currently targetting and grabbing
var z_target: Node3D = null
var grabbing : bool = false
var being_grabbed : bool = false
var grabbing_player : RollbackCharacterController = null

# used to show the floor indicator
@export var floor_indicator_enabled: bool = true

# determines if our inputs should affect our character 
@export var can_input: bool = true

var in_game : bool = false

# --------------------------------------- PRIVATE PROPERTIES ------------------------------------------- #

var _on_floor : bool = false
var _has_collision : bool = false
var _collision_normal : Vector3 = Vector3.UP

var _old_health: float = health
var _state: PlayerState = PlayerState.IDLE
var _flashing_time: float = 0.0
var _flashing_switch_time: float = 0.0
var _input_state_text: String = ""

var _can_block : bool = true
var _can_roll : bool = true

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

@onready var perfect_block_timer = $Cooldowns/PerfectBlockTimer
@onready var block_input_timer = $Cooldowns/BlockInputDebounce
@onready var roll_input_timer = $Cooldowns/RollInputDebounce

@onready var move_controller = $MoveController

# --------------------------------------- GLOBAL NODES ------------------------------------------- #

@onready var main_scene = get_tree().root.get_node("main_scene")
@onready var players = main_scene.get_node("Players")

# ------------------------------------------- SIGNALS --------------------------------------------- #

signal died
signal health_changed

# --------------------------------------- HELPER FUNCTIONS ------------------------------------------- #


# determines if we can jump input. We need to be on the floor and we need to be NOT blocking
func can_jump():
	return self._on_floor and not self.blocking


# traslates a vector3 of WASD/Joystick input into an input relative to the camera's orientation
func _get_camera_relative_input(input : Vector3) -> Vector3:
	if not self.current_cam: 
		return input
	
	var cam_right = self.current_cam.global_transform.basis.x
	var cam_forward = self.current_cam.global_transform.basis.z
	
	# make cam_forward horizontal:
	cam_forward = cam_forward.slide(Vector3.UP).normalized()
	
	# return camera relative input vector:
	return cam_forward * input.z + cam_right * input.x


# --------------------------------------- INPUT FUNCTIONS ------------------------------------------- #

# this function will determine the local input for WASD/Joystick
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
	if input_dir.length() > 0:
		total_input["input_vector"] = Vector2(input_dir.x, input_dir.z)


# this function will determine the local input for jumping
func _handle_jump_input(total_input : Dictionary) -> void:
	if Input.is_action_just_pressed("jump") and can_jump():
		total_input["pressed_jump"] = true


# this function will determine the local input targetiung and switching targets
func _handle_target_input(total_input : Dictionary) -> void:
	if Input.is_action_just_pressed("z_target"):
		total_input["pressed_target"] = true
	if Input.is_action_just_pressed("change_target"):
		total_input["pressed_change_target"] = true


# this function will determine the local input for holding block
func _handle_block_input(total_input : Dictionary) -> void:
	if Input.is_action_pressed("block"):
		total_input["holding_block"] = true


# this function will determine the local input for rolling/dodging
func _handle_roll_input(total_input : Dictionary) -> void:
	if Input.is_action_just_pressed("roll"):
		total_input["roll"] = true


# this function will determine the local input for abilities/moves
func _handle_move_input(total_input : Dictionary) -> void:
	for move_name in INPUT_MOVE_NAMES:
		if Input.is_action_pressed(move_name):
			total_input[move_name] = true


# --------------------------------------- PHYSICS PROCESS FUNCTIONS ------------------------------------------- #


# -- update the velocities of the character and then apply them
func _update_movement(dt) -> void:
	if !self.blocking:
		if self._on_floor:
			if self.move_direction.length() > 0.0:
				self._state = PlayerState.RUNNING
				self.velocity.x = self.move_direction.x * self.speed + self.knockback.x
				self.velocity.z = self.move_direction.z * self.speed + self.knockback.z

				# if player is moving left, flip the sprite
				self.sprite_flipped = (self.move_direction.x < 0)
			else:
				self._state = PlayerState.IDLE

				#TODO: Lowkey feels weird and could be better
				self.velocity.x = lerp(velocity.x, 0.0, dt * 7.0) + self.knockback.x
				self.velocity.z = lerp(velocity.z, 0.0, dt * 7.0) + self.knockback.z
		else:
			self.velocity.x = lerp(velocity.x, self.move_direction.x * self.air_speed, dt * 3.0)
			self.velocity.z = lerp(velocity.z, self.move_direction.z * self.air_speed, dt * 3.0)
			if velocity.y > 0.0:
				self._state = PlayerState.JUMPING
			else:
				self._state = PlayerState.FALLING
	else:
		if !self._on_floor:
			self.velocity.x = lerp(velocity.x, 0.0, dt * 3.0)
			self.velocity.z = lerp(velocity.z, 0.0, dt * 3.0)
		else:
			self.velocity.x = lerp(velocity.x, 0.0, dt * 7.0) + knockback.x
			self.velocity.z = lerp(velocity.z, 0.0, dt * 7.0) + knockback.z
			
	if !self.can_move:
		print("in the !can_move statement")
		self.velocity = knockback


# --------------------------------------- STAMINA RELATED FUNCTIONS ------------------------------------------- #


# used in the network update functions to update blocking values/times
func _update_block(is_holding_input : bool) -> void:
	# block_input_timer
	if is_holding_input and self.stamina > 0 and self._can_block:
		self._can_block = false
		self.blocking = true
		self._state = PlayerState.BLOCKING
		perfect_block_timer.start()
		self.perfect_blocking = true
		
	if self.blocking:
		if not is_holding_input or self.stamina <= 0:
			self.blocking = false
			self.stamina_recharge_cooldown = STAMINIA_RECHARGE_COOLDOWN
			block_input_timer.start()
			self._state = PlayerState.IDLE
			self.perfect_blocking = false


# used in network update to change our stamina values when blocking and when we're on cooldown 
func _update_stamina():
	# update the stamina bar visuals
	if stamina_bar:
		var stamina_ratio = (self.stamina / float(MAX_STAMINIA_TICKS)) * 100
		stamina_bar.update_stamina_bar(stamina_ratio)
	
	# if we have stamina and we're doing an action that requires stamina, we will update our values for this tick
	if self.stamina > 0:
		if self.blocking:
			self.stamina -= BLOCKING_STAMINA_USAGE_PER_TICK
	
	# if our stamina somehow goes below 0, set it to 0
	if self.stamina < 0:
		self.stamina = 0
	
	# dont continue any stamina updating if we're on stamina updating cooldown
	if self.stamina_recharge_cooldown > 0:
		self.stamina_recharge_cooldown -= 1
		return
		
	# recharge stamina if we're not on charging cooldown and if we're not blocking
	if self.stamina < MAX_STAMINIA_TICKS and not self.blocking:
		self.stamina += STAMINA_RECHARGE_PER_TICK


# --------------------------------------- VARIOUS PROCESS FUNCTIONS ------------------------------------------- #


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
	
	if self._on_floor:
		floor_ring.set_meta("goal_albedo_mix", 0.0)
	else:
		floor_ring.set_meta("goal_albedo_mix", 1.0)
	
	floor_ring.albedo_mix = lerp(floor_ring.albedo_mix, floor_ring.get_meta("goal_albedo_mix"), 12 * (0.016667))


# -- function that iterates through a player list and returns the one closest to self
# -- author: Kyle Senebouttarath
func get_closest_player() -> Array:
	
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
	return [closest_target, closest_distance]


# -- updates the z target if targetting is enabled
func _update_z_target() -> void:
	
	# if we're targetting, get the closest player as our target
	if self.targetting:
		self.z_target = self.get_closest_player()[0]
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
	self.debug_tag.visible = SHOW_DEBUG_INFO
	self.debug_tag.text = "PlayerState: " + PlayerState.keys()[_state] 
	#self.debug_tag.text += "\nAnimationNode: " + anim_tree_state_machine.get_current_node()
	#self.debug_tag.text += "\nTargetting: " + str(targetting)
	#self.debug_tag.text += "\nTarget: " + str(z_target)
	#self.debug_tag.text += "\nBlocking: " + str(self.blocking)
	self.debug_tag.text += "\nGrabbing: " + str(self.grabbing)
	self.debug_tag.text += "\nBeing Grabbed: " + str(self.being_grabbed)
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


# --------------------------------------- ROLLBACK FUNCTIONS ------------------------------------------- #


# this is a special virtual method that will get called by SyncManager
# this is because this node is part of the "network_sync" group
func _get_local_input() -> Dictionary:
	
	# track all of our player inputs in a dictionary
	var total_input := {}
	
	# gather all of our input sources
	if self.can_input:
		self._handle_block_input(total_input)
		self._handle_target_input(total_input)
		
		if not self.blocking:
			self._handle_directional_input(total_input)
			self._handle_jump_input(total_input)
			self._handle_roll_input(total_input)
		
		self._handle_move_input(total_input)
	
	# return all of our player's input
	return total_input


# custom code used to predict what the player's input may be if there is a rollback
# the better we can predict the player, the smaller the network artifacts
func _predict_remote_input(previous_input: Dictionary, _ticks_since_real_input: int) -> Dictionary:
		# clone new dictionary for the input
	var predicted_input = previous_input.duplicate()
	
	# it's very unlikely we will get two of these inputs in a row, so we can throw out these values
	# for example, full pressed space twice in 2 frames,
	predicted_input.erase("pressed_jump")
	predicted_input.erase("pressed_target")
	predicted_input.erase("pressed_change_target")
	predicted_input.erase("roll")
	
	# return new prediction
	return predicted_input


# this function will handle the new character controller's physics in a slightly more deterministic fashion
# please note that this function will likely evolve over time, and it should eventually be replaced to not use
# floating points since those are proven to be non-deterministic due to floating point errors
func _update_custom_physics(input : Dictionary, delta : float) -> void:
		#---- dont update any player physics if they're being grabbed
		# this effectively gives the other player full ownership over their physics
	if self.being_grabbed:
		self.velocity = Vector3.ZERO
		return
	
	#---- apply rolling forces
	var pressed_roll = input.get("roll", false)
	if pressed_roll and self._can_roll and self.stamina > ROLL_COST and self.move_direction and self.move_direction.length() > 0.0:
		self._can_roll = false
		roll_input_timer.start()
		self.stamina -= ROLL_COST
		self.stamina_recharge_cooldown = STAMINIA_RECHARGE_COOLDOWN
		self.velocity += self.move_direction * ROLL_VELOCITY
	
	#---- handle collisions with floor to determine if we're grounded or not
	var collision = move_and_collide(self.velocity * delta)
	if collision:
		self._has_collision = true
		self._collision_normal = collision.get_normal()
		
		# determine the angle we have with the floor
		var dot_product = self._collision_normal.dot(self.up_direction)
		var angle_radians = acos(dot_product)
		#var angle_degrees = angle_radians * 180.0 / PI
		
		# if we're on a slope, check to ensure the slope is shallow enough to be considered a floor. else, it's a wall and we're not grounded
		
		if (angle_radians <= self.floor_max_angle + FLOOR_ANGLE_THRESHOLD):
			self._on_floor = true
		else:
			self._on_floor = false
	else:	# if we're not touching anything
		self._has_collision = false
		self._collision_normal = Vector3.UP
		self._on_floor = false
	
	#---- apply gravity and jump forces
	if not self._on_floor:
		self.velocity.y -= gravity * delta
	else:
		var pressed_jump = input.get("pressed_jump", false)
		if pressed_jump:
			self.velocity.y += jump_power
	
	# TODO: This is messing up the _on_floor detection, so it's commented out
	#if self._has_collision:
	#	self.velocity = self.velocity.slide(self._collision_normal)
	
	#-- apply final positioning for physics
	self.position += (self.velocity * delta)


func _update_moves(input: Dictionary) -> void:
	# iterate through the move names and update the move controller
	for move_name in INPUT_MOVE_NAMES:
		var holding_move_input = input.get(move_name, false)
		move_controller.on_update(move_name, holding_move_input, self._on_floor)
	
	# update the debug text with the move input being put
	self._input_state_text = ""
	for move_name in INPUT_MOVE_NAMES:
		self._input_state_text += "\n" + move_name + ": " + str(input.get(move_name, false))


# this is essentially the "_process" method for this node, but with network sychronization
# NOTE: this is run on every TICK, not every FRAME
func _network_process(input: Dictionary) -> void:
	# get and set initial physics variables for easy state management
	var delta = (0.0166667)
	
	#if knockback > Vector3.ZERO:
		#self.can_move = false
		#print(can_move)
		#print("kb in RollbackCharacterController.gd:")
		#print(knockback)
		#pass
	#if kb_x > 0 or kb_y > 0 or kb_z > 0:
		#print(Vector3(kb_x, kb_y, kb_z))
		#velocity += Vector3(kb_x, kb_y, kb_z)
		#kb_x = 0
		#kb_y = 0
		#kb_z = 0
	
	# TODO: this should probably be changed to be something else
#	if event.is_action_pressed("pause"):
#		pause_menu_layer.toggle()
#	if pause_menu_layer.is_open():
#		return

	#-- get our blocking input and determine if we can be in the blocking state
	var is_holding_block_input : bool = input.get("holding_block", false)
	self._update_block(is_holding_block_input)
	
	#-- get our movement variables and update how we move
	var vector2Input : Vector2 = input.get("input_vector", Vector2.ZERO)
	self.move_direction = Vector3(vector2Input.x, 0, vector2Input.y)
	self._update_movement(delta)
	
	#-- update the rest of the stamina
	self._update_stamina()
	
	#-- update our targetting state
	var pressed_target : bool = input.get("pressed_target", false)
	if pressed_target:
		self.targetting = not self.targetting
	
	#-- update our targetting changing state
	var pressed_change_target : bool = input.get("pressed_change_target", false)
	if pressed_change_target:
		print("pressed change target input")
		pass #TODO: Implement
	
	# these probably shouldn't use delta anymore?
	#self._update_invincible_flash(delta)
	#self._update_block_recharge_delay(delta)
	
	#-- update the rest of our physics and apply the changes
	self._update_custom_physics(input, delta)
	
	#-- update animations
	#self.anim_tree.advance(delta * anim_speed_scale)
	#self._update_core_animations()
	sprite.flip_h = self.sprite_flipped
	
	# do other misc updates
	self._update_floor_indicator()
	self._update_z_target()
	self._update_debug_text()
	#self._update_health_change()
	
	# update grabbing positions
	if self.grabbing_player and self.grabbing:
		self.grabbing_player.velocity = Vector3.ZERO
		var cam_right = self.current_cam.global_transform.basis.x
		var horz_offset = cam_right if not self.sprite_flipped else -cam_right
		self.grabbing_player.global_position = self.global_position + Vector3(0, 0.25, 0) + horz_offset
	
	# update display name (in case it gets changed mid playtime)
	self.player_nametag.text = self.display_name
	
	#-- update moves
	self._update_moves(input)


# called at the end of every tick
func _save_state() -> Dictionary:
	return {
		#position = self.position,
		#velocity = self.velocity,
		
		can_move = self.can_move,
		move_direction = self.move_direction,	
		up_direction = self.up_direction,	
		on_floor = self._on_floor,
		
		state = self._state,
		
		has_collision = self._has_collision,
		collision_normal = self._collision_normal,
		
		#sprite_flipped = self.sprite_flipped,
		
		#health = self.health,
		#targetting = self.targetting,
		
		blocking = self.blocking,
		can_block = self._can_block,
		
		stamina = self.stamina,
		stamina_recharge_cooldown = self.stamina_recharge_cooldown,
		
		perfect_blocking = self.perfect_blocking,
		
		can_roll = self._can_roll,
		
		grabbing = self.grabbing,
		being_grabbed = self.being_grabbed,
		#knockback = self.knockback,
		kb_x = self.kb_x,
		kb_y = self.kb_y,
		kb_z = self.kb_z
	}


# called whenever a rollback is neccessary; applies state to our current scene
func _load_state(state: Dictionary) -> void:
	#self.position = state["position"] 
	#self.velocity = state["velocity"]
	
	self.can_move = state["can_move"]
	self.move_direction = state["move_direction"]
	self.up_direction = state["up_direction"]
	self._on_floor = state["on_floor"]
	
	self._state = state["state"]
	
	self._has_collision = state["has_collision"]
	self._collision_normal = state["collision_normal"]
	
	#self.sprite_flipped = state["sprite_flipped"]
	
	#self.health = state["health"]
	#self.targetting = state["targetting"]
	
	self.blocking = state["blocking"]
	self._can_block = state["can_block"]
	
	self.stamina = state["stamina"]
	self.stamina_recharge_cooldown = state["stamina_recharge_cooldown"]
	
	self.perfect_blocking = state["perfect_blocking"]
	
	self._can_roll = state["can_roll"]
	
	self.grabbing = state["grabbing"]
	self.being_grabbed = state["being_grabbed"]
	#self.knockback = state["knockback"]
	self.kb_x = state["kb_x"]
	self.kb_y = state["kb_y"]
	self.kb_z = state["kb_z"]


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
	self.anim_tree_state_machine.start("idle")
	#_move_controller = MoveController.new(self, $AnimationTree, $CharacterSprite, $Hurtbox)
	#add_child(_move_controller)


func _on_block_input_debounce_timeout():
	self._can_block = true


func _on_perfect_block_timer_timeout():
	self.perfect_blocking = false


func _on_roll_input_debounce_timeout():
	self._can_roll = true

# ---------------------------------------- END OF SCRIPT ------------------------------------------------- #

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
