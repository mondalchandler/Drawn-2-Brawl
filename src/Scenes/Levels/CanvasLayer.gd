extends CanvasLayer

@onready var levelHealthUI = $PlayerHealthUI
@onready var ingameCharacters = $"../Players"

#func _ready():
#	for character in ingameCharacters.get_children():
#		levelHealthUI.emit_signal("add_player", character)
		
func start():
	for character in ingameCharacters.get_children():
		levelHealthUI.emit_signal("add_player", character)


# --------- TEST CODE, DELETE ME LATER ---------- #

#@onready var testPlayer = $"../Players/TemplateCharacter"

#var currentGoal = 10.0
#var currentHpVal = 100.0
#var deltaCounter = 0.0

#func _process(delta):
	
	#deltaCounter += delta
	#if deltaCounter > 1.0:
	#	deltaCounter = 0.0
	#	if currentGoal == 90.0:
	#		currentGoal = 10.0
	#	else:
	#		currentGoal = 90.0
	
#	currentHpVal = lerp(currentHpVal, currentGoal, 8 * delta)
#	testPlayer.set_meta("Health", currentHpVal)
