extends CustomButton
@export var scene: String

func run_task():
	var root = get_node("../../../")
	root._change_scene(scene)
