extends CustomButton

@onready var parent = get_node("../../")

var current_map = null
var votes_for_start = false

func run_task():
	if multiplayer.is_server():
		main_scene.play_map()
	else:
		if not votes_for_start:
			votes_for_start = true
			vote_start.rpc_id(1)
		else:
			votes_for_start = false
			cancel_vote_start.rpc_id(1)
		
		
@rpc("any_peer", "call_remote", "reliable")
func vote_start():
	main_scene.vote_map_start()
	pass
@rpc("any_peer", "call_remote", "reliable")
func cancel_vote_start():
	main_scene.cancel_vote_map_start()
	pass
		
	#TODO: Spawn everyone else
	
	#main_scene.change_ui()
	
	#print("GO")
	#while not current_map:
	#	print("waiting")
	#	await get_tree().create_timer(0.1).timeout
	#current_map.spawn_player(character)
	#print("Hide ui")
	
	
	#print("what the heck")
	
	#main_scene.spawn_player_into_map(character)
	
	#var player = character.instantiate()
	#var spawn = main_scene.get_map().get_spawns()[0]
	#player.set_meta("spawn_point", spawn)
	#player.position = player.get_meta("spawn_point").position
	#player.display_name = "Player " + str(1)
	#main_scene.players.add_child(player)
		
	#if character:		
	#	var saloon_setup = func(saloon_scene):
	#		saloon_scene.players.push_front(character)
	#		# TODO: temp code: add two other players
	#		var test_dummy = load("res://src/Scenes/characters/Dummy.tscn")
	#		
	#		var test_dummy2 = load("res://src/Scenes/characters/Dummy.tscn")
	#		saloon_scene.players.append(test_dummy2)
	#		var test_dummy3 = load("res://src/Scenes/characters/Dummy.tscn")
	#		saloon_scene.players.append(test_dummy3)
	#	
	#	var saloon = main_scene._change_scene("res://src/Scenes/Levels/SaloonMap.tscn", saloon_setup)
	#	saloon.spawn_players()

#func _extra_ready():
	#print("helo")
	#if multiplayer.is_server():
		#self.visible = true
	#else:
		#self.visible = false

