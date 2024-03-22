# Alex Ottelien, Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Node


# ------------------ METHODS ------------------ #


var first = false
func _resized():
	if first:
		var children = get_node("Levels").get_children()
		children.append_array(get_node("FunctionButtons").get_children())
		for i in range(len(children)):
			children[i].position_method()
	else:
		first = true

