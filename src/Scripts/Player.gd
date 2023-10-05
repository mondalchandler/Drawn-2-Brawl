extends RigidBody3D

@onready var cam = get_viewport().get_camera_3d()
@onready var anim_player = $AnimationPlayer
@onready var hitbox = $MeshInstance3D2/Hitbox

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

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
	if area.is_in_group("enemy"):
		print("enemy hit")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var input := Vector3.ZERO
	var relative_input
	
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	relative_input = get_camera_relative_input(input)

	if Input.is_action_just_pressed("jump"):
		apply_impulse(Vector3.UP * 20.0, Vector3.ZERO)
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("melee_attack"):
		anim_player.play("melee_attack")
		hitbox.monitoring = true
	
	apply_central_force(relative_input * 2000.0 * delta)
	apply_central_force(Vector3.DOWN * 9.8 * mass)

	# Create a "Pac-Man" effect where if the player goes off one side of the stage, they appear on the other side.
	if position.x < -15.0:
		position.x = 15.0
	elif position.x > 15.0:
		position.x = -15.0
	elif position.z < -15.0:
		position.z = 15.0
	elif position.z > 15.0:
		position.z = -15.0
	else:
		pass
