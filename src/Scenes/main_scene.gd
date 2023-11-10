extends Node

@onready var current_scene = $MainMenu


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _change_scene(scene_path):
	var scene = load(scene_path)
	self.remove_child(current_scene)
	current_scene = scene.instantiate()
	self.add_child(current_scene)
	pass
