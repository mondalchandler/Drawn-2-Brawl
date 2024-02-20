# Chandler Frakes, Kyle Senebouttarath

# ------------------ IMPORTS ------------------ #

extends Node

# ------------------ VARIABLES ------------------ #

@onready var multiplayer_scenes = [
	"res://src/Scenes/UI/VictoryUI/victory_screen.tscn", 
	"res://src/Scenes/UI/player_select.tscn",
	"res://src/Scenes/Levels/SaloonMap.tscn"
]

@onready var perma_nodes = [
	$MusicNode, $PlayerLeaderboard
]

# ------------------ METHODS ------------------ #

#The following method will change the current scene to the scene at a given path.
#It will clear out the current main scene, then load the new scene to go to
#if a callback is provided, it will call the function BEFORE adding the new scene
func _change_scene(scene_path: String, optional_setup_callback = null):
	# load new scene
	var new_scene = load(scene_path).instantiate()
	
	# clear everything in the main scene
	for i in self.get_children():
		if not perma_nodes.has(i):
			i.queue_free()
	
	# if the callback is provided, use it
	if optional_setup_callback:
		optional_setup_callback.call(new_scene)
	
	# load the new scene
	self.add_child(new_scene)
	
	return new_scene


