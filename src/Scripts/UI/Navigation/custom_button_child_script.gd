extends Area2D


# Called when the node enters the scene tree for the first time.
# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionPolygon2D.polygon = get_parent().polygon
	pass # Replace with function body.


func _input_event(_viewport, event, _shape_idx):
	if(event is InputEventMouseButton and event.pressed):
		get_parent().run_task()
	pass
