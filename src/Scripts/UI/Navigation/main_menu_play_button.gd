
extends CustomButton

func run_task():
	get_node("../../AnimationPlayer").play("scene_transition")
	await get_tree().create_timer(.5).timeout
	main_scene.change_ui("res://src/Scenes/UI/play_scene.tscn")

