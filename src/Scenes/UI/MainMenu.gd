extends Control

func _on_play_pressed():
	# TODO: Switch out for actual game
	get_tree().change_scene_to_file("res://src/Scenes/Levels/TestLevel.tscn")

func _on_options_pressed():
	pass # Replace with function body.

func _on_quit_pressed():
	get_tree().quit()
