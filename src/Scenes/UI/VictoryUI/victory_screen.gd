# Kyle Senebouttarath

# ----------------- IMPORTS ------------------ #

extends CanvasLayer

# ----------------- GLOBALS ------------------ #

@onready var main_scene = get_tree().root.get_node("main_scene")

@onready var rematch_button: Button = $PanelContainer/MarginContainer/Rows/Options/RematchButton
@onready var character_select_button: Button = $PanelContainer/MarginContainer/Rows/Options/CharacterSelectButton
@onready var main_menu_button: Button = $PanelContainer/MarginContainer/Rows/Options/MainMenuButton
@onready var player_stats = $PanelContainer/MarginContainer/Rows/MarginContainer/PlayerStats

var player_card = preload("res://src/Scenes/UI/VictoryUI/player_card.tscn")
var rankings: Array = []
var previous_match_scene: Node3D
var level: String
var players = []

# ----------------- FUNCTIONS ------------------ #

func on_rematch():
	
	# obtain a path of the level to rematch
	var path = "res://src/Scenes/Levels/" + level + ".tscn"
	
	var rematch_setup = func(rematch_scene):
		rematch_scene.players = players
		rematch_scene.match_started = false
		rematch_scene.match_ended = false
	var rematch_scene = main_scene._change_scene(path, rematch_setup)
	rematch_scene.spawn_players()


func on_char_select():
	main_scene._change_scene("res://src/Scenes/UI/player_select.tscn")


func on_main_menu():
	main_scene._change_scene("res://src/Scenes/UI/main_menu.tscn")


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


