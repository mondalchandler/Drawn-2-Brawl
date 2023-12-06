# Chandler Frakes, Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Control

# --------------- VARIABLES ----------------- #

@onready var main_scene = get_tree().root.get_node("main_scene")

# ------------------ METHODS ------------------ #
var first = false
func _resized():
	if first:
		var children = get_node("Buttons").get_children()
#		children.append_array(get_node("FunctionButtons").get_children())
		for i in range(len(children)):
			children[i].position_method()
	else:
		first = true

#func _on_play_pressed():
#	main_scene._change_scene("res://src/Scenes/UI/player_select.tscn")
#
#
#func _on_options_pressed():
#	main_scene._change_scene("res://src/Scenes/UI/options_menu.tscn")
#
#
#func _on_quit_pressed():
#	get_tree().quit()
