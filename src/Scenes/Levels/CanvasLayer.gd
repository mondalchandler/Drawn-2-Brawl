extends CanvasLayer

@onready var levelHealthUI = $PlayerHealthUI
@onready var ingameCharacters = $"../Players"

func start():
	for character in ingameCharacters.get_children():
		levelHealthUI.emit_signal("add_player", character)

