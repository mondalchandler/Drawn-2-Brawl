extends RigidBody3D

#@onready get_node("RigidBody3D").scale = self.scale


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func get_parent_scale():
	return get_parent().scale
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
