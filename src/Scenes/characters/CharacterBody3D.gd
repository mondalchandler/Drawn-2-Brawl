# Chandler Frakes, Kyle Senebouttarath

extends CharacterBody3D

# ---------------- CONSTANTS ---------------- #

const SPEED = 5.0
const JUMP_VELOCITY = 15

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") + 25

# ---------------- GLOBALS ---------------- #

@onready var cam = get_viewport().get_camera_3d()
@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite3D
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var char = $"."

@onready var floor_raycast = $FloorRaycast
@onready var floor_ring = $FloorRing
@onready var floor_shadow = $FloorShadow

@onready var music_player = $"../MusicPlayer"

var spawn_point: Node

@export var knockback : Vector3 = Vector3.ZERO

var default_music_vol 
var invincible_timer = false
#var invincible = true

# char, offset, dmg_rng, hitstun, kb_len
var move_controller

var last_direction = Vector3(-.707, 0, -.707)

# ---------------- FUNCTIONS ---------------- #

# -- translates a vector3 to the same vector3, translated to the camera's offset
func get_camera_relative_input(input) -> Vector3:
	var cam_right = cam.global_transform.basis.x
	var cam_forward = cam.global_transform.basis.z
	# make cam_forward horizontal:
	cam_forward = cam_forward.slide(Vector3.UP).normalized()
	# return camera relative input vector:
	return cam_forward * input.z + cam_right * input.x

func _on_animation_player_animation_finished(anim_name):
	move_controller.anim_finished(anim_name)

func on_pause():
	music_player.emit_signal("enable_pause_music")

func on_unpause():
	music_player.emit_signal("disable_pause_music")

func _process(delta):
	#The following set of code will make the player flash and be invincible while respawning
	if(invincible_timer == true):
		invincible_timer = false
		for n in 4:
			await get_tree().create_timer(.125).timeout
			get_node("Sprite3D").hide()
			await get_tree().create_timer(.125).timeout
			get_node("Sprite3D").show()
		
#		await get_tree().create_timer(2).timeout
		set_meta("Invincible", false)
#		invincible = false
	#the following code will determine if a player has died, and if they have, respawn them
	if get_meta("Health") <= 0 && self.visible:
		self.visible = false
		self.get_node("Hurtbox").disabled = true
		await get_tree().create_timer(1).timeout
		set_meta("Invincible", true)
#		invincible = true
		invincible_timer = true
		set_meta("Health", get_meta("MaxHealth"))
		self.get_node("Hurtbox").disabled = false
		position = spawn_point.position
		self.visible = true

# -- called in the heartbeat loop, updates the positions of the floor indicators
func update_floor_shadow(dt):
	
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


# ---- heartbeat loop
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	var rel = get_camera_relative_input(input)

	var direction = (transform.basis * Vector3(rel.x, 0, rel.z)).normalized()

	if is_on_floor():	
		if direction:
			last_direction = direction
			velocity.x = direction.x * SPEED# + knockback
			velocity.z = direction.z * SPEED# + knockback
			
			if anim_player.is_playing() and anim_player.current_animation == "idle":
				anim_player.stop()
				anim_player.play("run")
				
			if not anim_player.is_playing():
				anim_player.play("run")
				
			# if player is moving left, flip the sprite
			if direction.x < 0:
				sprite.flip_h = true
			else:
				sprite.flip_h = false
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 7.0)
			if not anim_player.is_playing():
				anim_player.play("idle")
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 3.0)
		
	move_and_slide()
	
	if abs(velocity.y) > 1 and not anim_player.is_playing():
		anim_player.play("jump")
	if abs(velocity.y) <= 1 and  anim_player.current_animation == "jump" and is_on_floor():
		anim_player.play("idle")
	
	if Input.is_action_just_pressed("normal_close"):
		if (is_on_floor()):
			move_controller.attack(Move.new("MELEE", "Pistol Whip", [Transform3D(Basis.IDENTITY, Vector3(.5, 0, .5)), [10, 10], 0.1, 0.1, Vector3(4, 4, 4), Vector3(1.2, .8, 1)]))
		else:
			move_controller.attack(Move.new("GRAB", "Air Axe", []))
	if Input.is_action_just_pressed("normal_far"):
		if (is_on_floor()):
			move_controller.attack(Move.new("HITSCAN", "One Shot", [[10, 10], 0.2, Vector3(4, 4, 4)]))
		else:
			move_controller.attack(Move.new("GRAB", "Throwing Knife", []))
	if Input.is_action_just_pressed("special_close"):
		if (is_on_floor()):
			move_controller.attack(Move.new("GRAB", "Axe Uppercut", []))
		else:
			move_controller.attack(Move.new("GRAB", "Shotgun Explosion", []))
	if Input.is_action_just_pressed("special_far"):
		if (is_on_floor()):
			move_controller.attack(Move.new("GRAB", "Three Shot Burst", []))
		else:
			move_controller.attack(Move.new("GRAB", "Lasso Pull", []))
		
	update_floor_shadow(delta)

# ---------------- INPUT FUNCTIONS ---------------- #

signal toggle_game_paused

@onready var test_obj = load("res://src/Scenes/Objects/TestMovingPlatform2.tscn")
@onready var target = get_node("../../Camera3D")

var targeting = false
var target_number = 0

# when an input is registered
func _input(event : InputEvent):
	if (event.is_action_pressed("pause")):
		emit_signal("toggle_game_paused")
	
	#NOTE: this code is just test code to see if the target locking is working. This is not how attacks will actually spawn.
	if(event.as_text() == "Q" && event.pressed):
#		var test_obj = load("res://src/Scenes/Objects/TestMovingPlatform.tscn")
		var spawn_obj = test_obj.instantiate()
#		if(targeting):
		var test_basis = get_target_direction()
		spawn_obj.global_transform.basis = global_transform.basis.orthonormalized().slerp(test_basis, 1).scaled(scale)
		spawn_obj.position.y = 5
		spawn_obj.position.x = self.position.x
		spawn_obj.position.z = self.position.z
		$"../../".add_child(spawn_obj)
	
	if(event.as_text() == "P" && event.pressed):
		if($"../".get_children().size()>1):
			var temp = $"../".get_child(target_number)
			if(temp != self):
				target = temp
			else:
				target_number += 1
				if(target_number>=$"../".get_children().size()):
					target_number = 0
				target = $"../".get_child(target_number)
			target_number += 1
			if(target_number>=$"../".get_children().size()):
				target_number = 0
		else:
			targeting = false


func get_target_direction():
	return target.global_transform.looking_at(global_transform.origin, Vector3.UP).basis

# ---------------- INIT ---------------- #
	
func _ready():
	pause_menu.connect("on_pause_menu_open", on_pause)
	pause_menu.connect("on_pause_menu_close", on_unpause)
	anim_player.connect("animation_finished", _on_animation_player_animation_finished)
	
	move_controller = MoveController.new(self, anim_player, sprite, self.get_node("Hurtbox"))
