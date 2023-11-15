extends CustomButton



@onready var parent = get_node("../../")
@onready var main_scene = get_tree().root.get_node("main_scene")

func run_task():
	var character = parent.selectedCharacter
	if character:
		
		var saloon_setup = func(saloon_scene):
			saloon_scene.players.push_front(character)
			# TODO: temp code: add two other players
			var test_dummy = load("res://src/Scenes/Objects/DummyEnemy.tscn")
			saloon_scene.players.append(test_dummy)
			var test_dummy2 = load("res://src/Scenes/Objects/DummyEnemy.tscn")
			saloon_scene.players.append(test_dummy2)
		
		var saloon = main_scene._change_scene("res://src/Scenes/Levels/SaloonMap.tscn", saloon_setup)
		saloon.spawn_players()
#	var selectedCharacter = parent.selectedCharacter
#	if(selectedCharacter!=null):
#		var root = get_node("../../../")
#		#The following line will need to be deleted when level select is added
#		root._change_scene("res://src/Scenes/Levels/SaloonMap.tscn")
#		root.get_node("SaloonMap").players.push_front(selectedCharacter)
#		root.get_node("SaloonMap").spawn_players()
