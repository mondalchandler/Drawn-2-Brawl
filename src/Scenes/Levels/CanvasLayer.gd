extends CanvasLayer

@onready var levelHealthUI = $PlayerHealthUI

@onready var main_scene = get_tree().root.get_node("main_scene")
@onready var players = main_scene.get_node("Players")

func start():
	for character in players.get_children():
		levelHealthUI.emit_signal("add_player", character)

