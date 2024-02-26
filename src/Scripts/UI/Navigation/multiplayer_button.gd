extends CustomButton

#@onready var anim_player = get_node("../AnimationPlayer")
func run_task():
	print(get_node("../"))
	get_node("../../AnimationPlayer").play("slide_host_and_join")
	pass
