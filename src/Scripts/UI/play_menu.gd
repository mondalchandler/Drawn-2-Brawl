# Chandler Frakes, Kyle Senebouttarath

# --------------- IMPORT ----------------- #

extends Control

# --------------- VARIABLES ----------------- #

@onready var main_scene = get_tree().root.get_node("main_scene")

# ------------------ METHODS ------------------ #
var first = false

func _resized():
	if first:
		var children = get_node("Buttons").get_children()
#		children.append_array(get_node("FunctionButtons").get_children())
		for i in range(len(children)):
			children[i].position_method()
			
		var bg_children = get_node("Background").get_children()
		for i in range(len(bg_children)):
			bg_children[i].position_method()
	else:
		first = true

func scene_entered():
	get_node("AnimationPlayer").play("scene_entered")
