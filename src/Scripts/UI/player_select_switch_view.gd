extends CustomButton
@export var scene: String
#@onready var main_scene = get_tree().root.get_node("main_scene")

func run_task():
	var player_select = main_scene.ui_container.get_node("PlayerSelect")
	player_select.get_node("PlayerSelect").visible = !player_select.get_node("PlayerSelect").visible
	player_select.get_node("LevelSelect").visible = !player_select.get_node("LevelSelect").visible
