# Kyle Senebouttarath

# ----------------------- IMPORTS ----------------------- #

extends Control

# ----------------------- GLOBALS ----------------------- #

class_name PauseMenu 
@onready var pauseMenu = $"."

# ----------------------- VARIABLE SIGNALS ----------------------- #

# create a new boolean variable for pause state
var gamePaused : bool = false:
	get:	# when we try to get the value, we simply return it
		return gamePaused	
	set(value):		# when we change the value, change it and also send a signal saying we changed it
		gamePaused = value
		emit_signal("toggle_game_paused", gamePaused)

# ----------------------- EVENTS ----------------------- #

# toggles the UI visibility
func toggleUI(vis):
	if (vis):
		show()
	else:
		hide()
		

# hides the menu on game start
func _ready():
	hide()
	pauseMenu.connect("toggle_game_paused", toggleUI)
	
	
# when an input is registered
func _input(event : InputEvent):
	print(123)
	if (event.is_action_pressed("pause")):
		gamePaused = not gamePaused
		get_tree().paused = gamePaused
		
# ----------------------- SIGNAL CONNECTIONS ----------------------- #

# when pause mode is toggled
signal toggle_game_paused(isPaused : bool)

