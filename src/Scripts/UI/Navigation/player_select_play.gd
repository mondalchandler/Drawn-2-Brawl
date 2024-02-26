extends CustomButton

@onready var parent = get_node("../../")

var current_map = null

func on_new_map_loaded(new_map : Node):
	current_map = new_map


func on_map_unloaded(new_map : Node):
	current_map = null


func run_task():
	if multiplayer.is_server():
		main_scene.play_map(load("res://src/Scenes/Levels/SaloonMap.tscn"))
		
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

func _extra_ready():
	main_scene.map_spawner.spawned.connect(on_new_map_loaded)
	main_scene.map_spawner.despawned.connect(on_map_unloaded)
	
	if multiplayer.is_server():
		self.visible = true
	else:
		self.visible = false

