extends CustomButton



@onready var parent = get_node("../../")

func run_task():
	var selectedCharacter = parent.selectedCharacter
	if(selectedCharacter!=null):
		var root = get_node("../../../")
		#The following line will need to be deleted when level select is added
		root._change_scene("res://src/Scenes/Levels/SaloonMap.tscn")
		root.get_node("SaloonMap").players.push_front(selectedCharacter)
		root.get_node("SaloonMap").spawn_players()
