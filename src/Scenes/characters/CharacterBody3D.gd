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

# ---------------- FUNCTIONS ---------------- #
func get_camera_relative_input(input) -> Vector3:
	var cam_right = cam.global_transform.basis.x
	var cam_forward = cam.global_transform.basis.z
	# make cam_forward horizontal:
	cam_forward = cam_forward.slide(Vector3.UP).normalized()
	# return camera relative input vector:
	return cam_forward * input.z + cam_right * input.x

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "melee_attack":
		anim_player.play("idle")
		hitbox.monitoring = false

func _on_hitbox_area_entered(area):
	# TODO: Let controller know what to do/what was hit
	pass

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
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	if Input.is_action_just_pressed("melee_attack"):
		anim_player.play("melee_attack")
		hitbox.monitoring = true
