# Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Node

# --------------- GLOBALS ----------------- #

@onready var main_scene = get_tree().root.get_node("main_scene")
@onready var music_node = main_scene.get_node("MusicNode")

@onready var player_spawns: Node = $Spawns
@onready var players_node: = main_scene.get_node("Players")
@onready var char_spawner: MultiplayerSpawner = main_scene.get_node("CharacterSpawner")

enum GameMode {POINTS, LIVES, TRAINING}
@export var gamemode: GameMode = GameMode.LIVES

var match_ended: bool = false
var rankings = Array()
var starting_player_info: Array = []
var match_started: bool = false

# --------------------------------------- SERVER FUNCTIONS -------------------------------------------- #

func spawn_char_at_pos(data) -> Node:
	# get parameters out of data array
	var char_name = data[0]
	var spawn_index = data[1]
	var owner_peer_id = data[2]

	# create new player character
	var full_char_path = "res://src/Scenes/Characters/" + char_name + ".tscn"
	var char_scene = load(full_char_path)
	var new_player_char = char_scene.instantiate()
	
	# get spawn point and set player spawn
	var spawn_point = player_spawns.get_children()[spawn_index]
	new_player_char.set_meta("spawn_point", spawn_point)
	new_player_char.global_position = spawn_point.global_position
	if owner_peer_id and multiplayer.get_unique_id() == owner_peer_id:
		new_player_char.set_multiplayer_authority(owner_peer_id)
	else:
		new_player_char.set_multiplayer_authority(1)
	
	# give player name and display name and return them
		# the player name is important for the message serializer!
	new_player_char.name = "Player" + str(spawn_index + 1)
	new_player_char.display_name = "Player " + str(spawn_index + 1)
	new_player_char.id = (spawn_index + 1)
	
	# return newly spawned node
	return new_player_char


# spawns in the player characters listed in the players array
func spawn_players():
	for index in range(len(starting_player_info)):
		var player_info = starting_player_info[index]
		
		var char_name_to_create = player_info[0]
		var peer_id = player_info[1]
		
		if char_name_to_create:
			var full_char_path = "res://src/Scenes/Characters/" + char_name_to_create + ".tscn"
			if FileAccess.file_exists(full_char_path):
				var new_player_char = char_spawner.spawn([char_name_to_create, index, peer_id])
				if peer_id and new_player_char:
					new_player_char.set_multiplayer_authority(peer_id)


func insert_char_into_next_available_slot(character):
	rankings.insert(0, character.display_name)
	return


func update_players():
	for character in players_node.get_children():
		if not character.is_alive() and character.in_game:
			character.in_game = false
			insert_char_into_next_available_slot(character)


func get_alive_players():
	var alive_chars = []
	for character in players_node.get_children():
		if character.in_game:
			alive_chars.append(character)
	return alive_chars


# Called when the node enters the scene tree for the first time.
func start_match():
	music_node.stop()
	$CanvasLayer.start()
	for character in players_node.get_children():
		character.full_heal()
		character.in_game = true
	match_started = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not match_started:
		return
	
	if not multiplayer.is_server():
		return
	if not gamemode == GameMode.TRAINING:
		update_players()
		var current_alive_players = get_alive_players()
		
		if current_alive_players and current_alive_players.size() <= 1 and not match_ended:
			match_ended = true
			insert_char_into_next_available_slot(current_alive_players[0])
	else:
		for character in players_node.get_children():
			character.full_heal()
			character.lives = 100
		
		
		#var victory_screen_setup = func(victory_scene):
		#	victory_scene.rankings.assign(rankings)
		#	victory_scene.level = self.name
			#victory_scene.players = players
			#print(victory_scene.rankings)
		#main_scene.change_ui("res://src/Scenes/UI/VictoryUI/victory_screen.tscn", victory_screen_setup)


func _ready():
	char_spawner.set_spawn_function(self.spawn_char_at_pos)
	#char_spawner.spawn_function = 

