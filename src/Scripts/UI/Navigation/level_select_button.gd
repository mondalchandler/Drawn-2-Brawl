extends CustomButton


@export var map_path: String

# Called when the node enters the scene tree for the first time.
func run_task():
	main_scene.map_vote.rpc_id(1, map_path)
	pass

## Called every frame. 'delta' is the elapsed time since the previous frame.
#@rpc("any_peer", "call_local", "reliable")
#func map_vote(map_choice):
#	main_scene.map_votes[multiplayer.get_remote_sender_id()] = map_choice
#	pass
