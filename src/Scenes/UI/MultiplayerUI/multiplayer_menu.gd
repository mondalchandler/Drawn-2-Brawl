extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_host_pressed():
	get_tree().change_scene_to_file("res://src/Scenes/UI/MultiplayerUI/host_menu.tscn")


func _on_join_pressed():
	get_tree().change_scene_to_file("res://src/Scenes/UI/MultiplayerUI/join_menu.tscn")
