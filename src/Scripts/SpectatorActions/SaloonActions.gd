extends SpectatorActions


@onready var piano_timer = $NetworkTimer
@onready var load_piano = load("res://src/Scenes/Objects/Saloon Objects/piano_hazard.tscn")
var allow_piano = true

func action1(player_data):
	if allow_piano:
		allow_piano = false
		var piano = load_piano.instantiate()
	#following two lines need to be replaced by a different calculation
		piano.position.x = player_data.position.x * -1
		piano.position.z = player_data.position.z * -1
		piano.position.y = 30
		get_parent().add_child(piano)
		print("start")
		piano_timer.start()
	pass
	
func action2(player_data):
	pass
	
func action3(player_data):
	pass
	
func action4(player_data):
	pass
	
func _on_network_timer_timeout():
	print("hello")
	piano_timer.stop()
	allow_piano = true
