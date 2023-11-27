# Chandler Frakes, Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Control

# --------------- VARIABLES ----------------- #

@onready var main_scene = get_tree().root.get_node("main_scene")

# ------------------ METHODS ------------------ #

func _on_play_pressed():
	main_scene._change_scene("res://src/Scenes/UI/player_select.tscn")


func _on_options_pressed():
	main_scene._change_scene("res://src/Scenes/UI/options_menu.tscn")


func _on_quit_pressed():
	get_tree().quit()
