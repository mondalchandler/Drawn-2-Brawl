# Kyle Senebouttarath

# ----------------------- IMPORTS ----------------------- #

class_name PauseLayer
extends CanvasLayer

# ----------------------- GLOBALS ----------------------- #

@onready var main_scene = get_tree().root.get_node("main_scene")

@onready var pause_menu_panel = $PauseMenu/Panel

@onready var resume_button = $PauseMenu/Panel/VBoxContainer/ResumeButton
@onready var settings_button = $PauseMenu/Panel/VBoxContainer/SettingsButton
@onready var leave_button = $PauseMenu/Panel/VBoxContainer/LeaveButton
@onready var close_button = $PauseMenu/Panel/VBoxContainer/QuitGameButton

var char: CharacterBody3D = null

# ----------------------- VARIABLE SIGNALS ----------------------- #

var paused = false

signal on_pause_menu_open
signal on_pause_menu_close

# ----------------------- EVENTS ----------------------- #

func close():
	if paused:
		paused = false
		hide()
		emit_signal("on_pause_menu_close")


func open():
	if not paused:
		paused = true
		show()
		emit_signal("on_pause_menu_open")


# toggles the UI visibility
func toggle():
	if not paused:
		open()
	else:
		close()


func is_open():
	return paused


func client_disconnect():
	#TODO: Networking
	main_scene._change_scene("res://src/Scenes/UI/main_menu.tscn")


func game_quit():
	get_tree().quit()


# hides the menu on game start, set up connections
func _ready():
	hide()
	resume_button.pressed.connect(close)
	#TODO: Settings
	leave_button.pressed.connect(client_disconnect)
	close_button.pressed.connect(game_quit)
	


