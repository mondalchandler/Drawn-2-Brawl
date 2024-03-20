extends CustomButton
@export var scene: String
#@onready var main_scene = get_tree().root.get_node("main_scene")

func run_task():
	#main_scene.session_disconnect()
	main_scene.change_ui(scene)
