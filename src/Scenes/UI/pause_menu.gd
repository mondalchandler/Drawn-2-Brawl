# Kyle Senebouttarath

# ----------------------- IMPORTS ----------------------- #

extends Control

# ----------------------- GLOBALS ----------------------- #

@onready var pauseMenu = $Panel
@onready var char = $"../.."

# ----------------------- VARIABLE SIGNALS ----------------------- #

var paused = false

# ----------------------- EVENTS ----------------------- #

# toggles the UI visibility
func toggleUI():
	paused = not paused
	if (paused):
		show()
	else:
		hide()
		

# hides the menu on game start, set up connections
func _ready():
	hide()
	char.connect("toggle_game_paused", toggleUI)


