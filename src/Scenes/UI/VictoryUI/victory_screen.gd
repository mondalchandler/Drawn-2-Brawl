# Kyle Senebouttarath

# ----------------- IMPORTS ------------------ #

extends CanvasLayer

# ----------------- GLOBALS ------------------ #

@onready var main_scene = get_tree().root.get_node("main_scene")
@onready var music_node = main_scene.get_node("MusicNode")

@onready var rematch_button: Button = $PanelContainer/MarginContainer/Rows/Options/RematchButton
@onready var character_select_button: Button = $PanelContainer/MarginContainer/Rows/Options/CharacterSelectButton
@onready var main_menu_button: Button = $PanelContainer/MarginContainer/Rows/Options/MainMenuButton
@onready var player_stats = $PanelContainer/MarginContainer/Rows/MarginContainer/PlayerStats

var player_card = preload("res://src/Scenes/UI/VictoryUI/player_card.tscn")
var rankings = Array()
var previous_match_scene: Node3D
var level: String
var players = []

# ----------------- FUNCTIONS ------------------ #

func to_game_music():
	pass


func to_menu_music():
	music_node.load_song("res://resources/Music/MenuMusic/MenuMusic.tscn")
	music_node.play()


func on_rematch():
	
	# obtain a path of the level to rematch
	var path = "res://src/Scenes/Levels/" + level + ".tscn"
	
	var rematch_setup = func(rematch_scene):
		rematch_scene.players = players
		rematch_scene.match_started = false
		rematch_scene.match_ended = false
	var rematch_scene = main_scene._change_scene(path, rematch_setup)
	rematch_scene.spawn_players()
	to_game_music()


func on_char_select():
	main_scene._change_scene("res://src/Scenes/UI/player_select.tscn")
	to_menu_music()


func on_main_menu():
	main_scene._change_scene("res://src/Scenes/UI/main_menu.tscn")
	to_menu_music()


# Called when the node enters the scene tree for the first time.
func _ready():
	rematch_button.pressed.connect(on_rematch)
	character_select_button.pressed.connect(on_char_select)
	main_menu_button.pressed.connect(on_main_menu)
	
	var size = rankings.size()
	var placement = 0
	if size > 0:
		for player in rankings:
			var char_name = rankings[placement]
			var new_card = player_card.instantiate()
			new_card.player_name = char_name
			placement = placement + 1 
			new_card.placement = placement
			player_stats.add_child(new_card)


