class_name CustomButton
extends Polygon2D

@onready var main_scene = get_tree().root.get_node("main_scene")
# Called when the node enters the scene tree for the first time.
func _ready():
	position_method()
	pass # Replace with function body.


#this method exists as a just in case, where I can't change the position any other way.
@onready var x = self.position.x
@onready var y = self.position.y
@onready var default_res_x: float = 1920
@onready var default_res_y: float = 1080
func position_method():
	var size = get_tree().root.size
	var scale_x = size.x/default_res_x
	var scale_y = size.y/default_res_y
	self.position.x = x*scale_x
	self.position.y = y*scale_y
	self.scale.x = scale_x
	self.scale.y = scale_y
	pass
	
func run_task():
	pass
