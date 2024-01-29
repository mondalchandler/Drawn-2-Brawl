extends BaseHitbox
class_name Projectile

@export var speed: int

var direction

# ------------------- INIT AND LOOP --------------------- #

func emit():	
	self.direction = get_direction()
	self.active = true


func get_direction():
	if owner_char.targetting:
		return owner_char.global_position.direction_to(owner_char.z_target.global_position)
	else:
		if (!owner_char.sprite.flip_h):
			return owner_char.global_position.direction_to(Vector3(owner_char.global_position.x + 1000, 0, owner_char.global_position.x + 1000))
		else:
			return owner_char.global_position.direction_to(Vector3(owner_char.global_position.x - 1000, 0, owner_char.global_position.x - 1000))


# this only runs when the node and ITS CHILDREN and loaded
func _ready() -> void:
	# turn off collisions with default world
	self.set_collision_layer_value(1, false)
	# hitboxes will be on layer 2
	self.set_collision_layer_value(2, true)
	
	# set hitboxes to detect for areas on layer 1, but not layer 2
	self.set_collision_mask_value(1, true)
	self.set_collision_mask_value(2, false)
	
	self.connect("area_entered", area_entered)
	self.connect("body_entered", body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.active:
		self.global_position += self.speed * self.direction * delta
		self.hit_chars = {}
		self.monitoring = true
		if self.debug_on == true and self.mesh_instance != null:
			self.mesh_instance.visible = true
	else:
		self.global_position = owner_char.global_position
		self.monitoring = false
		self.hit_chars = {}
		if self.mesh_instance != null:
			self.mesh_instance.visible = false


func _init(speed = 0):	
	super()
	self.speed = speed
