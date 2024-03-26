extends CustomButton

#@onready var anim_player = get_node("../AnimationPlayer")
func run_task():
	get_node("../../AnimationPlayer").play("slide_host_and_join")
	pass
