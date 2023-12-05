extends CustomButton

@onready var parent = get_node("../../")

func run_task():
	var character = parent.selectedCharacter
	
	if character:		
		var saloon_setup = func(saloon_scene):
			saloon_scene.players.push_front(character)
			# TODO: temp code: add two other players
			var test_dummy = load("res://src/Scenes/characters/Dummy.tscn")
			saloon_scene.players.append(test_dummy)
			var test_dummy2 = load("res://src/Scenes/characters/Dummy.tscn")
			saloon_scene.players.append(test_dummy2)
			var test_dummy3 = load("res://src/Scenes/characters/Dummy.tscn")
			saloon_scene.players.append(test_dummy3)
		
		var saloon = main_scene._change_scene("res://src/Scenes/Levels/SaloonMap.tscn", saloon_setup)
		saloon.spawn_players()
