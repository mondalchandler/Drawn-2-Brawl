# Chandler Frakes, Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Control

# --------------- VARIABLES ----------------- #



# ------------------ METHODS ------------------ #

func _on_play_pressed():
	get_tree().change_scene_to_file("res://src/Scenes/Levels/TestLevel.tscn")


func _on_options_pressed():
	get_tree().change_scene_to_file("res://src/Scenes/UI/options_menu.tscn")


func _on_quit_pressed():
	get_tree().quit()


func _on_multiplayer_pressed():
	global.multiplayer_ = true
	get_tree().change_scene_to_file("res://src/Scenes/UI/multiplayer.tscn")
