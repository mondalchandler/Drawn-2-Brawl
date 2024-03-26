extends SpectatorActions


@onready var piano_timer = $NetworkTimer
@onready var load_piano = load("res://src/Scenes/Objects/Saloon Objects/piano_hazard.tscn")



	
func action1(data: Dictionary):
	var piano = load_piano.instantiate()
#following two lines need to be replaced by a different calculation
	piano.position.x = data["position"].x * -1
	piano.position.z = data["position"].z * -1
	piano.position.y = 30
	get_parent().add_child(piano)
	pass
func action2(data: Dictionary):
	pass
	
func action3(data: Dictionary):
	pass
	
func action4(data: Dictionary):
	pass

func _ready():
	action1_cooldown = 300
