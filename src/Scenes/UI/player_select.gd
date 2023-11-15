extends Node
@onready var selectedCharacter: PackedScene = null

#The folowing function will take in a PackedScene of a character and send it over to another scene to be instantiated.
#It will first get the parent node, which will be the root node of the whole project, and call its change scene method.
#This currently will set the scene to only the saloon map, as that is out only map, and will then call the maps "spawn_players" method.
func _load_player(character):
	selectedCharacter = character
#	if(character):
#		var parent = get_parent()
#		#The following line will need to be deleted when level select is added
#		parent._change_scene("res://src/Scenes/Levels/SaloonMap.tscn")
#		parent.get_node("SaloonMap").players.push_front(character)
#		parent.get_node("SaloonMap").spawn_players()
	pass
	
	
var first = false
func _resized():
	if first:
		var children = get_node("CharacterButtons").get_children()
		for i in range(len(children)):
			children[i].position_method()
	else:
		first = true
	pass
