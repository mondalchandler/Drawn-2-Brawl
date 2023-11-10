extends Area2D

@onready var Character: PackedScene = get_parent().Character
@onready var parent: Node = get_node("../../../")



# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionPolygon2D.polygon = get_parent().polygon
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func _input_event(viewport, event, shape_idx):
	if(event is InputEventMouseButton and event.pressed):
		parent._load_player(Character)
#		print(get_parent().get_parent().get_parent())
	pass
