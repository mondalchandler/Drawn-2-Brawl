# Chandler Frakes, Kyle Senebouttarath

# ------------------ IMPORTS ------------------ #

extends Node

# ------------------ VARIABLES ------------------ #

#@onready var multiplayer_scenes = [
#	"res://src/Scenes/UI/VictoryUI/victory_screen.tscn", 
#	"res://src/Scenes/UI/player_select.tscn",
#	"res://src/Scenes/Levels/SaloonMap.tscn"
#]

#@onready var perma_nodes = [
#	$MusicNode, $Leaderboard, $Players, $Map, $MapSpawner
#]

@onready var ui_container = $UI
@onready var players = $Players
@onready var map_container = $Map
@onready var map_spawner = $MapSpawner

# -------------------------------------- PRIVATE METHODS ----------------------------------------- #


func _get_current_map():
	if map_container.get_child_count() > 0:
		return map_container.get_child(0)
	return null


func _spawn_players_into_map(map):
	if not map: return
	
	# get all connected players
	var all_players = multiplayer.get_peers()
	
	# add ourself to the players 
	all_players.append(1)
	
	# spawn in every play, including ourself
	for id in all_players:
		var character = load("res://src/Scenes/Characters/RollbackBaseCharacter.tscn")#load("res://src/Scenes/characters/Ranger.tscn")
		map.players.append(character)
		self.change_ui.rpc_id(id)
	
	# get the remaining player slots
	var remaining_slots = 4 - all_players.size()
	
	# if we have remaining slots, add dummies
	for i in remaining_slots:
		var dummy = load("res://src/Scenes/characters/Dummy.tscn")
		map.players.append(dummy)
	
	# spawn players and start match
	map.spawn_players()
	
	# give a little time to ping data
	# 2 second delay to allow sync manager to gather ping data to synchronize the start for all clients
	await get_tree().create_timer(2.0).timeout
	SyncManager.start()



func _start_map(map_scene: PackedScene):
	# Remove old map if any
	for c in map_container.get_children():
		map_container.remove_child(c)
		c.queue_free()
	
	# load the new map
	var loaded_map = map_scene.instantiate()
	
	# Add new map
	map_container.add_child(loaded_map)
	
	#spawn players into the map
	self._spawn_players_into_map(loaded_map)


func _on_sync_started():
	var map = self._get_current_map()
	if map:
		map.start_match()


func _on_sync_stopped():
	pass


func _ready():
	SyncManager.connect("sync_started", self._on_sync_started)
	SyncManager.connect("sync_stopped", self._on_sync_stopped)


# -------------------------------------- PUBLIC METHODS ----------------------------------------- #


func session_disconnect():
	# disconnect multiplayer 
	if multiplayer.has_multiplayer_peer():
		if multiplayer.is_server():
			players.shutdown_server()
		else:
			players.disconnect_client()


func play_map(map_scene: PackedScene):
	if multiplayer.is_server():
		#using call_deferred allows existing map cleanup logic to be called before the scene cleans up
		self._start_map.call_deferred(map_scene)


#The following method will change the current scene to the scene at a given path.
#It will clear out the current main scene, then load the new scene to go to
#if a callback is provided, it will call the function BEFORE adding the new scene
@rpc("any_peer", "call_local", "reliable")
func change_ui(ui_scene_path: String = "", optional_setup_callback = null):

	# clear everything in the ui scene
	for c in ui_container.get_children():
		ui_container.remove_child(c)

	# if a new ui was not provided, then don't continue
	if not ui_scene_path or ui_scene_path == "": 
		return null
	
	# load new UI scene
	var new_ui_scene = load(ui_scene_path).instantiate()

	# if the callback is provided, use it
	if optional_setup_callback:
		optional_setup_callback.call(new_ui_scene)

	# load the new scene
	ui_container.add_child(new_ui_scene)

	return new_ui_scene

