# Kyle Senebouttarath

# ----------------------- IMPORTS ----------------------- #

extends Control

# ----------------------- GLOBALS ----------------------- #

@onready var pauseMenu = $Panel
@onready var char = $"../.."

# ----------------------- VARIABLE SIGNALS ----------------------- #

var paused = false

# create a new boolean variable for pause state
#var gamePaused : bool = false:
#	get:	# when we try to get the value, we simply return it
#		return gamePaused	
#	set(value):		# when we change the value, change it and also send a signal saying we changed it
#		gamePaused = value
#		emit_signal("toggle_game_paused", gamePaused)

# ----------------------- EVENTS ----------------------- #

# toggles the UI visibility
func toggleUI():
	paused = not paused
	if (paused):
		show()
	else:
		hide()
		

# hides the menu on game start
func _ready():
	hide()
	char.connect("toggle_game_paused", toggleUI)
	#cha.connect("toggle_game_paused", toggleUI)
	
	
# when an input is registered
#func _input(event : InputEvent):
#	print(123)
#	if (event.is_action_pressed("pause")):
#		gamePaused = not gamePaused
#		get_tree().paused = gamePaused
		
# ----------------------- SIGNAL CONNECTIONS ----------------------- #

# when pause mode is toggled
#signal toggle_game_paused(isPaused : bool)

