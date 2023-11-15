# Kyle Senebouttarath

# ----------------- IMPORTS ------------------ #

extends CanvasLayer

# ----------------- GLOBALS ------------------ #

@onready var rematch_button: Button = $PanelContainer/MarginContainer/Rows/Options/RematchButton
@onready var character_select_button: Button = $PanelContainer/MarginContainer/Rows/Options/CharacterSelectButton
@onready var main_menu_button: Button = $PanelContainer/MarginContainer/Rows/Options/MainMenuButton
@onready var player_stats = $PanelContainer/MarginContainer/Rows/MarginContainer/PlayerStats

var player_card = preload("res://src/Scenes/UI/player_card.tscn")
var rankings: Array = []
var previous_match_scene: Node3D
var level: String
var players = []

# ----------------- FUNCTIONS ------------------ #

func on_rematch():
	
	# obtain a path of the level to rematch
	var path = "res://src/Scenes/Levels/" + level + ".tscn"
	
	# clear the main_scene 
	var parent = get_parent()
	for i in parent.get_children():
		i.queue_free()
	
	# load a new previous level and add it to main_scene, then play
	var game_scene = load(path).instantiate();
	game_scene.players = players
	game_scene.match_started = false
	game_scene.match_ended = false
	parent.add_child(game_scene)
	game_scene.spawn_players()


func on_char_select():
	var parent = get_parent()
	
	for i in parent.get_children():
		i.queue_free()
		
	var main_menu_scene = load("res://src/Scenes/UI/player_select.tscn").instantiate();
	parent.add_child(main_menu_scene)


func on_main_menu():
	var parent = get_parent()
	
	for i in parent.get_children():
		i.queue_free()
		
	var main_menu_scene = load("res://src/Scenes/UI/main_menu.tscn").instantiate();
	parent.add_child(main_menu_scene)


# Called when the node enters the scene tree for the first time.
func _ready():
	rematch_button.pressed.connect(on_rematch)
	character_select_button.pressed.connect(on_char_select)
	main_menu_button.pressed.connect(on_main_menu)
	
	var size = rankings.size()
	for placement in range(size - 1, -1, -1):
		var names_in_placement = rankings[placement]
		if names_in_placement.size() > 0:
			var char_name = names_in_placement[0]
			if char_name:
				var new_card = player_card.instantiate()
				new_card.player_name = char_name
				new_card.placement = rankings.size() - (placement)
				player_stats.add_child(new_card)


