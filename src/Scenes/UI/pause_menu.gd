# Kyle Senebouttarath

# ----------------------- IMPORTS ----------------------- #

extends Control

# ----------------------- GLOBALS ----------------------- #

@onready var pauseMenu = $Panel
@onready var char = $"../.."

# ----------------------- VARIABLE SIGNALS ----------------------- #

var paused = false

signal on_pause_menu_open
signal on_pause_menu_close

# ----------------------- EVENTS ----------------------- #

# toggles the UI visibility
func toggleUI():
	paused = not paused
	if (paused):
		show()
		emit_signal("on_pause_menu_open")
	else:
		hide()
		emit_signal("on_pause_menu_close")
		

# hides the menu on game start, set up connections
func _ready():
	hide()
	char.connect("toggle_game_paused", toggleUI)


