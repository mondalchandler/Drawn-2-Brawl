extends Node
class_name SpectatorActions



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func parse_action(event, player_data):
	if event.has("normal_close"):
		action1(player_data)
		pass
	elif event.has("normal_far"):
		action2(player_data)
		pass
	elif event.has("special_close"):
		action3(player_data)
		pass
	elif event.has("special_far"):
		action4(player_data)
		pass
	pass
	
func action1(player_data):
	pass
	
func action2(player_data):
	pass
	
func action3(player_data):
	pass
	
func action4(player_data):
	pass
