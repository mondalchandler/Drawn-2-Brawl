# Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Node

# --------------- GLOBALS ----------------- #

@onready var main_scene = get_tree().root.get_node("main_scene")

@onready var player_spawns: Node = $Spawns
@onready var players_node: Node = $Players

var match_ended: bool = false
var rankings: Array = [[], [], [], []]
var players: Array = []
var match_started: bool = false

# --------------- FUNCTIONS ----------------- #

func spawn_players():
	for i in range(len(players)):
		var player = players[i].instantiate()
		player.spawn_point = player_spawns.get_children()[i]
		player.position = player.spawn_point.position
		players_node.add_child(player)
	$CanvasLayer.start()
	start_match()


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
func start_match():
	for char in players_node.get_children():
		if not char.has_meta("Health"):
			char.set_meta("Health", 100)
		char.set_meta("InGame", true)
	match_started = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	print()
#	print(str(get_node("Objects/low_poly_table_test/RigidBody3D").scale))
#	print(str(get_node("Objects/low_poly_table_test/RigidBody3D/CollisionShape3D").scale))
#	print(str(get_node("Objects/low_poly_table_test/RigidBody3D/Cylinder").scale))
#	print()
#	get_node("Objects/low_poly_table_new2").scale = Vector3(8, 8, 8)
	if not match_started:
		return

	update_players()
	var current_alive_players = get_alive_players()
	if current_alive_players and current_alive_players.size() <= 1 and not match_ended:
		match_ended = true
		insert_char_into_next_available_slot(current_alive_players[0])
		
		var victory_screen_setup = func(victory_scene):
			victory_scene.rankings = rankings
			victory_scene.level = self.name
			victory_scene.players = players
		main_scene._change_scene("res://src/Scenes/UI/victory_screen.tscn", victory_screen_setup)
