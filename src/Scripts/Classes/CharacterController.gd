# Chandler Frakes, Kyle Senebouttarath, Alex Ottelien

# ---------------- IMPORTS ---------------- #

class_name CharacterController 
extends CharacterBody3D

# ---------------- CONSTANTS ---------------- #

const FLASH_DELAY: float = 0.125
const MOVE_MAP_NAMES = ["ground_nc", "ground_nf", "ground_sc", "ground_sf", "air_nc", "air_nf", "air_sc", "air_sf"]
const TARGET_ARROW_DEFAULT_SIZE: float = 0.0002

# ---------------- PROPERTIES ---------------- #

# note: you can use self to refer to the character
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") + 15
@export var health: float = 100
@export var max_health: float = 100
@export var display_name: String = "TestCharacter"
@export var in_game: bool = true
@export var knockback : Vector3 = Vector3.ZERO

@export var speed: float = 5.0
@export var air_speed: float = 5.0
@export var jump_power: float = 15

@export var move_direction: Vector3 = Vector3.ZERO

@export var anim_speed_scale: float = 1.0

@export var invincible: bool = false
@export var blocking: bool = false
@export var grabbing: bool = false
@export var dodging: bool = false
@export var can_move = true

@export var floor_indicator_enabled: bool = true
@export var can_player_input: bool = true
@export var _show_debug_info: bool = true

@export var ground_nc: Move = null
@export var ground_nf: Move = null
@export var ground_sc: Move = null
@export var ground_sf: Move = null
@export var air_nc: Move = null
@export var air_nf: Move = null
@export var air_sc: Move = null
@export var air_sf: Move = null

# Enums
enum PlayerState { IDLE, RUNNING, JUMPING, FALLING, KNOCKBACK}

var z_target: Node3D = null
var targetting: bool = false
var grab_target: Node3D = null

# ---------------- PRIVATE ---------------- #

var _old_health: float = health
var _state: PlayerState = PlayerState.IDLE
var _flashing_time: float = 0.0
var _flashing_switch_time: float = 0.0
var _input_state_text: String = ""
var _move_controller = null

# ---------------- CLIENT INSTANCES ---------------- #

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
@onready var players: Node = self.get_parent()
	
@onready var target_arrow: Sprite3D = $TargetArrow
@onready var pause_menu_layer: PauseLayer = $PauseLayer

# ---------------- SIGNALS ---------------- #

signal died
signal health_changed

# ---------------- PRIVATE FUNCTIONS ---------------- #

# -- updates the z target if targetting is enabled
func _update_z_target(dt: float) -> void:
	if targetting:
		var closest_target: Node3D = null
		var closest_distance: float = INF
		for player in players.get_children():
			if player != self:
				var dist: float = (self.global_position - player.global_position).length()
				if dist <= closest_distance:
					closest_distance = dist
					closest_target = player
		if closest_target:
			z_target = closest_target
	else:
		z_target = null
	
	if z_target:
		target_arrow.global_position = z_target.global_position + Vector3(0, z_target.global_transform.basis.y.length() * 1.5, 0)
		target_arrow.show()
	else:
		target_arrow.hide()
	target_arrow.pixel_size = TARGET_ARROW_DEFAULT_SIZE + sin(Time.get_ticks_msec() * 0.0125) * 0.000015

# -- updates the 3d text for debug information. append more information if need be
func _update_debug_text() -> void:
	debug_tag.global_position = self.global_position + Vector3(0, 1, 0)
	if self.current_cam:
		debug_tag.global_position += self.current_cam.global_transform.basis.x * 2
	debug_tag.visible = _show_debug_info
	debug_tag.text = "PlayerState: " + PlayerState.keys()[_state] 
	debug_tag.text += "\nAnimationNode: " + anim_tree_state_machine.get_current_node()
	debug_tag.text += "\nTargetting: " + str(targetting)
	debug_tag.text += "\nTarget: " + str(z_target)
	debug_tag.text += "\n" + _input_state_text

# -- given the current state of the player, update the animation tree
func _update_core_animations() -> void:
	if _state == PlayerState.IDLE:
		anim_tree_state_machine.travel("idle")
	elif _state == PlayerState.RUNNING:
		anim_tree_state_machine.travel("run")
	elif _state == PlayerState.JUMPING:
		anim_tree_state_machine.travel("jump")
	elif _state == PlayerState.FALLING:
		anim_tree_state_machine.travel("jump")

# -- update the velocities of the character and then apply them
func _update_movement(delta: float) -> void:
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
	if !can_move:
		velocity = knockback
			
	move_and_slide()

# -- translates a vector3 to the same vector3, translated to the camera's offset
func _get_camera_relative_input(input) -> Vector3:
	if not self.current_cam: return Vector3.ZERO
	
	var cam_right = self.current_cam.global_transform.basis.x
	var cam_forward = self.current_cam.global_transform.basis.z
	# make cam_forward horizontal:
	cam_forward = cam_forward.slide(Vector3.UP).normalized()
	# return camera relative input vector:
	return cam_forward * input.z + cam_right * input.x

# -- updates the positions of the floor indicators
func _update_floor_indicator(dt: float) -> void:
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
	
	floor_ring.albedo_mix = lerp(floor_ring.albedo_mix, floor_ring.get_meta("goal_albedo_mix"), 12 * dt)

# -- checks if the player health has changed; if so, send a signal
func _update_health_change() -> void:
	if self.health != self._old_health:
		emit_signal("health_changed", self.health, self._old_health)
		self._old_health = self.health

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
		
		
# -- converts the move name to the type for the move controller
# -- NOT FULLY IMPLEMENTED DUE TO LACK OF MOVES
func _move_name_to_type(name):
	if name == "ground_nc":
		return ""
	if name == "ground_nf":
		return ""
	if name == "ground_sc":
		return ""
	if name == "ground_sf":
		return ""
	if name == "air_nc":
		return ""
	if name == "air_nf":
		return ""
	if name == "air_sc":
		return ""
	if name == "air_sf":
		return ""

# ---------------- PUBLIC FUNCTIONS ---------------- #

func full_heal() -> void:
	health = max_health

func is_alive() -> bool:
	return health > 0.0

func perform_invincible_frame_flashing(time_length: float) -> void:
	_flashing_time = time_length

func set_camera(cam: Camera3D) -> void:
	self.current_cam = cam

func take_damage(damage: float) -> void:
	self.health -= damage
	if self.health <= 0:
		self.health = 0
		emit_signal("died")

# TODO: When provided a desination vector, move the player to said direction
func move_to(destination: Vector3) -> void:
	pass

# ----------------  MAIN FUNCTIONS ---------------- #

# Constructor
func _init() -> void:
	pass


# -- called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim_tree_state_machine.start("idle")
	_move_controller = MoveController.new(self, $AnimationTree, $CharacterSprite, $Hurtbox)
	add_child(_move_controller)


# -- called when the user inputs anything  
func _input(event : InputEvent) -> void:
	if not can_player_input:
		return
	
	if event.is_action_pressed("pause"):
		pause_menu_layer.toggle()
	
	if pause_menu_layer.is_open():
		return
	
	# targetting
	if event.is_action_pressed("z_target"):
		targetting = not targetting
	
	# jumping
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y += jump_power
	
	# move inputs
	if event.is_pressed():
		_input_state_text = ""
		
		# TODO: MoveController requires that the move animation name be in the MOVE_MAP_NAMES array
		#		in order to spawn the hitbox correctly. This required creating 4 extra states
		#		since each input has 2 outcomes (1 for on ground, 1 for in air). As a result, the
		#		input will not match with what move is actually being output in the debugger text.
		for name in MOVE_MAP_NAMES:
			_input_state_text += "\n" + name + ": " + str(event.is_action_pressed(name))
		
		if is_on_floor():
			if event.is_action_pressed("normal_close"):
				_move_controller.attack(ground_nc)
			if event.is_action_pressed("normal_far"):
				_move_controller.attack(ground_nf)
			if event.is_action_pressed("special_close"):
				_move_controller.attack(ground_sc)
			if event.is_action_pressed("special_far"):
				_move_controller.attack(ground_sf)
		else:
			if event.is_action_pressed("normal_close"):
				_move_controller.attack(air_nc)
			if event.is_action_pressed("normal_far"):
				_move_controller.attack(air_nf)
			if event.is_action_pressed("special_close"):
				_move_controller.attack(air_sc)
			if event.is_action_pressed("special_far"):
				_move_controller.attack(air_sf)


# -- updates every frame aswell, but can fluxate or be more consistent since its based on the physics task process
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.z = Input.get_axis("move_forward", "move_back")
	
	# if we have a camera, move relative to it
	if self.current_cam:
		var relative_move_dir = _get_camera_relative_input(input_dir)
		var dir = (self.transform.basis * Vector3(relative_move_dir.x, 0, relative_move_dir.z)).normalized()
		if can_player_input:
			move_direction = dir
		_update_movement(delta)
	
	# update animations
	anim_tree.advance(delta * anim_speed_scale)
	_update_core_animations()


# -- called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_z_target(delta)
	player_nametag.text = display_name
	_update_debug_text()
	_update_floor_indicator(delta)
	_update_health_change()
	_update_invincible_flash(delta)
