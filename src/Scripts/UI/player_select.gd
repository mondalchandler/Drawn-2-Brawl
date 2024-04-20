# Alex Ottelien, Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Node

# --------------- VARIABLES ----------------- #

#@onready var main_scene = get_tree().root.get_node("main_scene")
@onready var selectedCharacter: PackedScene = null
var vs_CPU = false

# ------------------ METHODS ------------------ #

#The folowing function will take in a PackedScene of a character and send it over to another scene to be instantiated.
#It will first get the parent node, which will be the root node of the whole project, and call its change scene method.
#This currently will set the scene to only the saloon map, as that is out only map, and will then call the maps "spawn_players" method.
func _load_player(character):
	selectedCharacter = character


var first = false
func _resized():
	if first:
		var children = get_node("PlayerSelect/CharacterButtons").get_children()
		children.append_array(get_node("PlayerSelect/FunctionButtons").get_children())
		children.append_array(get_node("LevelSelect/FunctionButtons").get_children())
		children.append_array(get_node("LevelSelect/LevelButtons").get_children())
		children.append_array(get_node("MenuButtons").get_children())
		for i in range(len(children)):
			children[i].position_method()
		#get_node("LevelSelect/Background").position_method()
		#get_node("PlayerSelect/Background").position_method()
	else:
		first = true
