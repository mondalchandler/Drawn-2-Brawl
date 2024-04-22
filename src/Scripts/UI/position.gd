extends Node

@onready var x = self.position.x
@onready var y = self.position.y
@onready var default_res_x: float = 1920
@onready var default_res_y: float = 1080

# ------------------ HELPER FUNCTIONS ------------------- #


func position_method():
	var size = get_tree().root.size
	print(size)
	var scale_x = size.x/default_res_x
	var scale_y = size.y/default_res_y
	print(scale_x)
	self.position.x = x*scale_x
	self.position.y = y*scale_y
	self.scale.x = scale_x
	self.scale.y = scale_y
	
func _ready():
	position_method()
