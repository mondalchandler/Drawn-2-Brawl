extends Polygon2D

var touching := false
var following := false
var default_scale := scale

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if following:
		position = get_local_mouse_position() * 1.1


func _on_area_2d_mouse_entered():
	touching = true
	scale = default_scale * 1.2
	print(touching)



func _on_area_2d_mouse_exited():
	touching = false
	scale = default_scale
	print(touching)



func _on_area_2d_input_event(viewport, event, shape_idx):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and touching:
		following = !following
