# Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Node

# --------------- GLOBALS ----------------- #

@onready var players_node: Node3D = $Players
var match_ended: bool = false
var rankings: Array = [[], [], [], []]

# --------------- FUNCTIONS ----------------- #

func insert_char_into_next_available_slot(char):
	for placement in rankings:
		if placement.size() == 0:
			placement.append(char.name)
			return


func update_players():
	for char in players_node.get_children():
		if char.get_meta("Health") != null and char.get_meta("Health") <= 0 and char.get_meta("InGame"):
			char.set_meta("InGame", false)
			insert_char_into_next_available_slot(char)


func get_alive_players():
	var alive_chars = []
	for char in players_node.get_children():
		if char.get_meta("InGame"):
			alive_chars.append(char)
	return alive_chars


# Called when the node enters the scene tree for the first time.
func _ready():
	for char in players_node.get_children():
		if not char.has_meta("Health"):
			char.set_meta("Health", 100)
		char.set_meta("InGame", true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_players()
	var current_alive_players = get_alive_players()
	if current_alive_players and current_alive_players.size() <= 1 and not match_ended:
		match_ended = true
		insert_char_into_next_available_slot(current_alive_players[0])
		var victory_scene = load("res://src/Scenes/UI/victory_screen.tscn").instantiate();
		victory_scene.rankings = rankings
		victory_scene.level = get_tree().current_scene.name
		add_child(victory_scene)
		
