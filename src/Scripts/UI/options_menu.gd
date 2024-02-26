extends Control

@onready var main_scene = get_tree().root.get_node("main_scene")

func _on_back_pressed():
	main_scene.change_ui("res://src/Scenes/UI/main_menu.tscn")

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
