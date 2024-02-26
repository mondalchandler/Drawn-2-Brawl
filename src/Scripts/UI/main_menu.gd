# Chandler Frakes, Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Control

# --------------- VARIABLES ----------------- #


# ------------------ METHODS ------------------ #

var first = false

func _resized():
	if first:
		var children = get_node("Buttons").get_children()
		for i in range(len(children)):
			children[i].position_method()
	else:
		first = true

