# Chandler Frakes

extends BaseHitbox
class_name Projectile

# HOW TO ADD CUSTOM PROJECTILES
	# 1) Create a new scene, call it whatever you want
			# a) We reparent projectiles to the map scene so that they can move independently of the player.
			#    Doing so requires that we instantiate a PackedScene of the projectile we are spawning.
			#    The next few steps are the same as those in BaseHitbox.gd, since all we are creating is a
			#    moving hitbox.
	# 2) Attatch a MeshInstance3D as well as a CollisionShape3D node to Projectile node
	# 3) In Projectile node, assign the mesh and collision shape to the corresponding varialbes
	# 4) In the corresponding Move node, assign the projectile_path node to the path of the proj. scene
		# a) From this point forward, one should be able to mess around with the custom parameters,
		#    position/size of the mesh
		# b) WE USE MOVE_DATA HERE!!!!!!!!!!!!!!!!!!!!!!!!!!
		#    Because some moves require multiple projectiles for the same animation, we need to provide
		#    the information of how many times we repeat the projectile, and at what times they appear.
		#    We use a timer to delay the next proj. from appearing, so the second parameter in move_data
		#    should be an array (size of which == repeated_times) that has each offset (try best to match
		#    with animation). The format is as such:
		#        [ repeated_times: int, [ delay_1: float, delay_2: float, etc. ] ]
		#        Ex:    [ 3, [ 0.1, 0.2, 0.2 ] ]
		#    Check out MoveController.gd to see how we interact with this data.

# ---------------------------------------- CONSTANTS ------------------------------------------ #

const TICKS_PER_SECOND : float = 30.0
const DELTA : float = (1.0 / TICKS_PER_SECOND)

# ---------------- PROPERTIES ----------------- #

@export var speed: int

var direction
var target_displayed = false
var image = load("res://resources/Images/red_crosshair.png")
var target = Sprite3D.new()
var map

# ---------------- FUNCTIONS ---------------- #

func display_target():
	if !self.target_displayed:
		if self.owner_char.targetting:
			var scale = 0.17
			self.target.scale = Vector3(scale, scale, scale)
			self.target.texture = self.image
			self.target.billboard = true
			self.target.transparency = 0.5
			
			self.map = get_parent()
			self.map.add_child(self.target)
			self.map.move_child(self.target, self.map.get_child_count() - 1)
			self.target.global_position = self.owner_char.z_target.global_position
			self.target_displayed = true		


# overrideable virtual method.
func _after_hit_computation() -> void:
	queue_free()


func emit():	
	self.direction = get_direction()
	self.active = true


func get_direction():
	if self.owner_char and self.owner_char.targetting and self.owner_char.z_target:
		return self.owner_char.global_position.direction_to(self.owner_char.z_target.global_position)
	else:
		# if not targetting, simply shoot left or right
		if (!self.owner_char.sprite.flip_h):
			return self.owner_char.global_position.direction_to(Vector3(self.owner_char.global_position.x + 1000, 0, self.owner_char.global_position.x + 1000))
		else:
			return self.owner_char.global_position.direction_to(Vector3(self.owner_char.global_position.x - 1000, 0, self.owner_char.global_position.x - 1000))

# ------------------- INIT AND LOOP --------------------- #

# this only runs when the node and ITS CHILDREN have loaded
func _ready() -> void:
	# turn off collisions with default world
	# hitboxes will be on layer 3
	self.set_collision_layer_value(3, true)
	
	# set hitboxes to detect for areas on layer 2 and 5
	self.set_collision_mask_value(2, true)
	self.set_collision_mask_value(5, true)


func _network_process(input: Dictionary) -> void:
	if self.active:
		if self.target_displayed:
			self.map.remove_child(self.target)
		self.global_position += self.speed * self.direction * DELTA
		self.hit_chars = {}
		self.monitoring = true
		if self.debug_on == true and self.mesh_instance != null:
			self.mesh_instance.visible = true
	else:
		display_target()
		self.global_position = self.owner_char.global_position
		self.monitoring = false
		self.hit_chars = {}
		if self.mesh_instance != null:
			self.mesh_instance.visible = false
	
	if self.monitoring and self.has_overlapping_bodies():
		for body in self.get_overlapping_bodies():
			on_collision_detected(body)


func _save_state() -> Dictionary:
	return {
		global_position = self.global_position,
		speed = self.speed,
		direction = self.direction
	}


func _load_state(state: Dictionary) -> void:
	self.global_position = state["global_position"]
	self.speed = state["speed"]
	self.direction = state["direction"]


func _init(speed = 0):
	super()
	self.speed = speed
