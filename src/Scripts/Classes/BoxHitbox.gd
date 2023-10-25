# Kyles45678
# This class extends the basic hitbox to create a box hitbox

# ---------------- IMPORTS ------------------- #

extends BaseHitbox
class_name BoxHitbox

# ---------------- PROPERTIES ----------------- #


# ---------------- METHODS ------------------- #

func _init(char, offset: Transform3D, dmg_rng: Array, hitstun: float, kb_len: float, hitbox_size: Vector3) -> void:
	super(char, offset, dmg_rng, hitstun, kb_len)
	
	# create parent for hitbox
	var box_mesh = BoxMesh.new()
	self.mesh_instance = MeshInstance3D.new()
	
	self.mesh_instance.mesh = box_mesh
	self.mesh_instance.transform = offset
	
	self.mesh_instance.scale = hitbox_size
	self.mesh_instance.visible = false
	
	
	self.mesh_instance.add_child(self)
	
	# create a box shape, set the size, and add it to self
	var shape = BoxShape3D.new()
	shape.extents = hitbox_size
	self.collision_shape = CollisionShape3D.new()
	self.collision_shape.shape = shape
	self.add_child(self.collision_shape)



# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
