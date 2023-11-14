extends Control

func _on_back_pressed():
	get_parent()._change_scene("res://src/Scenes/UI/main_menu.tscn")
#	get_tree().change_scene_to_file("res://src/Scenes/UI/main_menu.tscn")

func _on_display_pressed():
	pass
	
func _apply_changes():
#	print(str(self.size))
#	print(str(get_window().size))
	var root = get_tree().root;
	root.size = Vector2 (1000,1000);
	get_window().size = Vector2 (1000, 1000)
	get_viewport().size = Vector2 (1000, 1000)
	pass
