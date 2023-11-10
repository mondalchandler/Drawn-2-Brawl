extends Node


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _load_player(character):
	if(character):
		var parent = get_parent()
		#The following line will need to be deleted when level select is added
		parent._change_scene("res://src/Scenes/Levels/SaloonMap.tscn")
		parent.get_children()[0].players.push_front(character)
		parent.get_children()[0].spawn_players()
	pass
