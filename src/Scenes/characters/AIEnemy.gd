extends CharacterBody3D


const SPEED = 3.0
const JUMP_VELOCITY = 4.0

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

@onready var floor_raycast = $FloorRaycast
@onready var floor_ring = $FloorRing
@onready var floor_shadow = $FloorShadow


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "melee_attack":
		test_hitbox._deactivate()
		pass


func _physics_process(delta):
	# apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# move automatically towards the player
	velocity = Vector3.ZERO
	nav_agent.set_target_position(player.global_transform.origin)
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = ((next_nav_point - global_transform.origin).normalized() * SPEED) + knockback
		
	# if the player is within 1 unit of another player, attack!
	if global_transform.origin.distance_to(player.global_transform.origin) < 2.0:
		if anim_player.is_playing():
			anim_player.stop()
		anim_player.play("melee_attack")
		test_hitbox._activate()
		
	# if we are moving, play the run animation, else play the idle animation
	if is_on_floor():
		if velocity.length() > 0.1:
			if anim_player.is_playing() and anim_player.current_animation == "idle":
				anim_player.stop()
				anim_player.play("run")
			
			if not anim_player.is_playing():
				anim_player.play("run")
				
			# if player is moving left, flip the sprite
			if velocity.x < 0:
				$Sprite3D.flip_h = true
			else:
				$Sprite3D.flip_h = false
		else:
			anim_player.play("idle")
		
	if abs(velocity.y) > 1 and not anim_player.current_animation == "melee_attack":
		anim_player.play("jump")
	if abs(velocity.y) <= 1 and  anim_player.current_animation == "jump" and is_on_floor():
		anim_player.play("idle")
		
	update_floor_shadow(delta)
		
	if can_move:
		move_and_slide()


func _ready():
	anim_player.connect("animation_finished", _on_animation_player_animation_finished)
	player = get_node(player_path)
	test_hitbox = BoxHitbox.new(self, Transform3D(Basis.IDENTITY, Vector3(1, 0, 0)), [10, 15], 0, 0, Vector3(0.6, 0.8, 1))
	test_hitbox.set_debug_mode(true)
	char.add_child(test_hitbox.mesh_instance)


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
