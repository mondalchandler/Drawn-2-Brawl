extends RigidBody3D

#@onready get_node("RigidBody3D").scale = self.scale


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
#	print(str(self.scale))
#	print("hello")
#	var scale = get_parent().scale
#	get_node("CollisionShape3D").scale = scale
#	get_node("Cylinder").scale = scale
#	get_node("RigidBody3D").scale = self.scale
#	pass # Replace with function body.

func get_parent_scale():
	return get_parent().scale
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
#func _physics_process(delta):
#	velocity = move_and_slide(velocity, Vector2.UP)
	
#func _on_hitbox_area_entered(area):
#	if(area == "attack"):
#		get_node("Destructible").destroy()
#	# TODO: Let controller know what to do/what was hit
#	pass
