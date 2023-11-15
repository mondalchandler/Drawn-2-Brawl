extends Node

@onready var current_scene = $MainMenu


#The following method will change the current scene to the scene at a given path.
#It will then remove the previous scene as a child and add the new scene as a child. 
func _change_scene(scene_path):
	var scene = load(scene_path)
	
	for i in self.get_children():
		i.queue_free()
	current_scene = scene.instantiate()
	self.add_child(current_scene)
