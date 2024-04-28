extends Button

@export var move: String

func _init():
	toggle_mode = true

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_unhandled_input(false)
	update_text()
	pass # Replace with function body.

func _toggled(toggled_on):
	set_process_unhandled_input(toggled_on)
	if toggled_on:
		text = "<Select Input>"
		release_focus()
	else:
		update_text()
		grab_focus()

func _unhandled_input(event):
	if event.pressed:
		InputMap.action_erase_events(move)
		InputMap.action_add_event(move, event)
		
		button_pressed = false
		


func update_text():
	text = InputMap.action_get_events(move)[0].as_text()
