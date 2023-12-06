extends CustomButton


func run_task():
	var player_select_setup = func(player_select_scene):
		player_select_scene.vs_CPU = true
		
	
	main_scene._change_scene("res://src/Scenes/UI/player_select.tscn", player_select_setup)
