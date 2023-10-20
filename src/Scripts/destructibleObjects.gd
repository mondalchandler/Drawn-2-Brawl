extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_hitbox_area_entered(area):
	if(area == "attack"):
		get_node("Destructible").destroy()
	# TODO: Let controller know what to do/what was hit
	pass
