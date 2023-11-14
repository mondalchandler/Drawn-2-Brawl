extends Node


# Called when the node enters the scene tree for the first time.
#var players = [load("res://src/Scenes/characters/templateCharacter.tscn"),
# load("res://src/Scenes/characters/templateCharacter.tscn"),
# load("res://src/Scenes/characters/templateCharacter.tscn"),
# load("res://src/Scenes/characters/templateCharacter.tscn")]

#var players = [load("res://src/Scenes/characters/templateCharacter.tscn")]
var players = []

#The following method will spawn all players who are in the game.
#It currently does this by instaniating every player in an array and then adding them to their set spawn points.
func spawn_players():
	for i in range(len(players)):
		var player = players[i].instantiate()
		player.spawn_point = get_node("Spawns").get_children()[i]
		player.position = player.spawn_point.position
		get_node("Players").add_child(player)
	$CanvasLayer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#The code in this method is just for testing purposes
var one_kill = true
func _process(delta):
	if(one_kill):
		one_kill = false
		await get_tree().create_timer(5).timeout
		get_node("Players").get_children()[0].set_meta("Health", 0)
		await get_tree().create_timer(1).timeout
		one_kill = true
	pass
	
	

