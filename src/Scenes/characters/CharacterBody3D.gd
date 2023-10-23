# Chandler Frakes, Kyle Senebouttarath

extends CharacterBody3D

# ---------------- CONSTANTS ---------------- #

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# ---------------- GLOBALS ---------------- #

@onready var cam = get_viewport().get_camera_3d()
@onready var anim_player = $AnimationPlayer
@onready var hitbox = $MeshInstance3D2/Hitbox
@onready var pause_menu = $CanvasLayer/PauseMenu

@onready var music_player = $"../MusicPlayer"

var default_music_vol 

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
	if anim_name == "melee_attack":
		hitbox.monitoring = false


func _on_hitbox_area_entered(area):
	# TODO: Let controller know what to do/what was hit
	pass


func on_pause():
	music_player.emit_signal("enable_pause_music")


func on_unpause():
	music_player.emit_signal("disable_pause_music")


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
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			anim_player.play("run")
			# if player is moving left, flip the sprite
			if direction.x < 0:
				$Sprite3D.flip_h = true
			else:
				$Sprite3D.flip_h = false
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 7.0)
			if not anim_player.is_playing():
				anim_player.play("idle")
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 3.0)
		
	move_and_slide()
	
	if Input.is_action_just_pressed("jump"):
		anim_player.play("jump")
	
	if Input.is_action_just_pressed("melee_attack"):
		if anim_player.is_playing():
			anim_player.stop()
		anim_player.play("melee_attack")
		hitbox.monitoring = true

# ---------------- INPUT FUNCTIONS ---------------- #

signal toggle_game_paused

@onready var test_obj = load("res://src/Scenes/Objects/TestMovingPlatform2.tscn")
var targeting = false
@onready var target = get_node("../../Camera3D")
var target_number = 0
var last_direction = Vector3.ZERO

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
#			print(str(rad_to_deg(atan(last_direction.x/last_direction.z))))
#
#			print(str(last_direction.x/last_direction.z))
#		else:
#			spawn_obj.position.y = 5
#			spawn_obj.position.x = self.position.x
#			spawn_obj.position.z = self.position.z
#			print(str(rad_to_deg(atan(last_direction.x/last_direction.z))))
#			spawn_obj.rotation.y = round(rad_to_deg(atan(last_direction.x/last_direction.z)))
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
	#need to place code here for projectile spawning when not targeting
#	if(targeting):
	return target.global_transform.looking_at(global_transform.origin, Vector3.UP).basis
#	else:
#		return self.global_transform.looking_at(global_transform.origin, Vector3.UP).basis

# ---------------- INIT ---------------- #
	
func _ready():
	pause_menu.connect("on_pause_menu_open", on_pause)
	pause_menu.connect("on_pause_menu_close", on_unpause)
