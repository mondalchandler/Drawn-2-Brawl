# Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Node

# --------------- GLOBALS ----------------- #

@onready var main_scene = get_tree().root.get_node("main_scene")
@onready var music_node = main_scene.get_node("MusicNode")

@onready var player_spawns: Node = $Spawns
@onready var players_node: = main_scene.get_node("Players")

enum GameMode {POINTS, LIVES}
@export var gamemode: GameMode = GameMode.LIVES

var match_ended: bool = false
var rankings = Array()
var starting_player_info: Array = []
var match_started: bool = false

# --------------------------------------- SERVER FUNCTIONS -------------------------------------------- #

# spawns in the player characters listed in the players array
func spawn_players():
	for index in range(len(starting_player_info)):
		var player_info = starting_player_info[index]
		var char_to_create = player_info[0]
		var peer_id = player_info[1]
		
		if char_to_create:
			var new_player_char = char_to_create.instantiate()
			new_player_char.set_meta("spawn_point", player_spawns.get_children()[index])
			new_player_char.position = new_player_char.get_meta("spawn_point").position
			new_player_char.display_name = "Player " + str(index + 1)
			players_node.add_child(new_player_char)
			
			if peer_id:
				new_player_char.set_multiplayer_authority(peer_id)


func insert_char_into_next_available_slot(char):
	rankings.insert(0, char.display_name)
	return


func update_players():
	for char in players_node.get_children():
		if not char.is_alive() and char.in_game:
			char.in_game = false
			insert_char_into_next_available_slot(char)


func get_alive_players():
	var alive_chars = []
	for char in players_node.get_children():
		if char.in_game:
			alive_chars.append(char)
	return alive_chars


# Called when the node enters the scene tree for the first time.
func start_match():
	music_node.stop()
	$CanvasLayer.start()
	for char in players_node.get_children():
		char.full_heal()
		char.in_game = true
	match_started = true


#var one_kill = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not match_started:
		return
		
	update_players()
	var current_alive_players = get_alive_players()
	if current_alive_players and current_alive_players.size() <= 1 and not match_ended:
		match_ended = true
		insert_char_into_next_available_slot(current_alive_players[0])
		
		var victory_screen_setup = func(victory_scene):
			victory_scene.rankings.assign(rankings)
			victory_scene.level = self.name
			#victory_scene.players = players
			print(victory_scene.rankings)
		main_scene.change_ui("res://src/Scenes/UI/VictoryUI/victory_screen.tscn", victory_screen_setup)
