extends Control

var in_room: bool = false

var player_limit = 2

func _ready():
	if "--server" in OS.get_cmdline_args():
		var scene = load("res://src/Scenes/Levels/TestLevel.tscn").instantiate();
		scene.multiplayer_authority = true
		get_tree().root.call_deferred("add_child", scene)
		hide()

func _on_create_room_pressed():
	$"Create Ctrl".visible = true
	$"Join Ctrl".visible = false


func _on_join_room_pressed():
	$"Create Ctrl".visible = false
	$"Join Ctrl".visible = true


func _on_join_submit_pressed():
	var scene = load("res://src/Scenes/Levels/TestLevel.tscn").instantiate()
	get_tree().root.add_child(scene)
	hide()


func _on_create_submit_pressed():
	var scene = load("res://src/Scenes/Levels/TestLevel.tscn").instantiate();
	scene.multiplayer_authority = true
	get_tree().root.add_child(scene)
	hide()


func _on_back_pressed():
	get_tree().change_scene_to_file("res://src/Scenes/UI/main_menu.tscn")
	

