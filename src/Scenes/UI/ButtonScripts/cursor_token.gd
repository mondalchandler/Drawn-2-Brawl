extends Polygon2D

var touching := false
var following := false
var default_scale := scale
var scale_mod := 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	scale = default_scale * scale_mod
	if following:
		position = to_global(get_local_mouse_position())


func _on_area_2d_mouse_entered():
	touching = true
	if not following:
		scale_mod = 1.1


func _on_area_2d_mouse_exited():
	touching = false
	if not following:
		scale_mod = 1.0


func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and touching:
			if event.pressed:
				following = !following
				scale_mod = 0.9
			else:
				if following:
					scale_mod = 1.1
				else:
					scale_mod = 1
