extends Node
class_name SpectatorActions

var action1_cooldown = 0
var action2_cooldown = 0
var action3_cooldown = 0
var action4_cooldown = 0

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
	
#func action1(player_data):
#	pass
func action1(data: Dictionary):
	pass
	
func action2(data: Dictionary):
	pass
	
func action3(data: Dictionary):
	pass
	
func action4(data: Dictionary):
	pass
