extends CustomButton
@export var scene: String
#@onready var main_scene = get_tree().root.get_node("main_scene")

func run_task():
	var player_select = main_scene.ui_container.get_node("PlayerSelect")
	var p_children = player_select.get_node("PlayerSelect").get_children()
	var l_children = player_select.get_node("LevelSelect").get_children()
	print("hi")
	for i in range(len(p_children)):
		p_children[i].visible = !p_children[i].visible
	for i in range(len(l_children)):
		l_children[i].visible = !l_children[i].visible
	#player_select.get_node("PlayerSelect").visible = !player_select.get_node("PlayerSelect").visible
	#player_select.get_node("LevelSelect").visible = !player_select.get_node("LevelSelect").visible
