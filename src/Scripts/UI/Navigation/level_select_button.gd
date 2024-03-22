extends CustomButton


@export var map_path: String

# Called when the node enters the scene tree for the first time.
func run_task():
	map_vote.rpc()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
@rpc("any_peer", "call_local", "reliable")
func map_vote():
	#if main_scene.map_votes.has(multiplayer.get_remote_sender_id()):
	main_scene.map_votes[multiplayer.get_remote_sender_id()] = map_path
		
	pass
