extends SpectatorActions

@onready var load_piano = load("res://src/Scenes/Objects/Saloon Objects/low_poly_piano.tscn")
func action1(player_data):
	var piano = load_piano.instantiate()
#following two lines need to be replaced by a different calculation
	piano.position.x = player_data.position.x * -1
	piano.position.z = player_data.position.z * -1
	piano.position.y = 30
	get_parent().add_child(piano)
	pass
	
func action2(player_data):
	pass
	
func action3(player_data):
	pass
	
func action4(player_data):
	pass
