extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var player = null
var test_hitbox
@export var knockback : Vector3 = Vector3.ZERO

@export var player_path : NodePath
@export var can_move = true

@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $AnimationPlayer
@onready var char = $"."


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "melee_attack":
		test_hitbox._deactivate()
		pass


func _physics_process(delta):	
	velocity = Vector3.ZERO
	nav_agent.set_target_position(player.global_transform.origin)
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = ((next_nav_point - global_transform.origin).normalized() * SPEED) + knockback
		
	if can_move:
		move_and_slide()
		
	# if the player is within 1 unit of another player, play the "melee_attack" animation
	if global_transform.origin.distance_to(player.global_transform.origin) < 2.0:
		print('here')
		if anim_player.is_playing():
			anim_player.stop()
		anim_player.play("melee_attack")
		test_hitbox._activate()


func _ready():
	player = get_node(player_path)
	test_hitbox = BoxHitbox.new(self, Transform3D(Basis.IDENTITY, Vector3(1, 0, 0)), [10, 15], 0, 0, Vector3(0.6, 0.8, 1))
	test_hitbox.set_debug_mode(true)
	char.add_child(test_hitbox.mesh_instance)
