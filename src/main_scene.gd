# Chandler Frakes, Kyle Senebouttarath

# ------------------ IMPORTS ------------------ #

extends Node

# ------------------ CONSTANTS ------------------ #

const LOG_FILE_DRECTORY = "user://detailed_logs"
const LOGGING_ENABLED := true
const FORCE_SALOON := true
const FORCE_CASTLE := false

# ------------------ VARIABLES ------------------ #

#@onready var multiplayer_scenes = [
#	"res://src/Scenes/UI/VictoryUI/victory_screen.tscn", 
#	"res://src/Scenes/UI/player_select.tscn",
#	"res://src/Scenes/Levels/SaloonMap.tscn"
#]

#@onready var perma_nodes = [
#	$MusicNode, $Leaderboard, $Players, $Map, $MapSpawner
#]

var vs_CPU = false

const START_TIMEOUT_MAX = 15
var start_timeout = START_TIMEOUT_MAX
var num_votes = 0
@onready var start_timer = $VoteStartTimer

@onready var ui_container = $UI
@onready var players = $Players
@onready var map_container = $Map
@onready var map_spawner = $MapSpawner
var map_votes = {}

@export var spawn_dummies : bool = false

# -------------------------------------- PRIVATE METHODS ----------------------------------------- #

@rpc("any_peer", "call_local", "reliable")
func map_vote(map_choice):
	map_votes[multiplayer.get_remote_sender_id()] = map_choice
	pass


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
		var character_path = "RollbackRangerCharacter"#load("res://src/Scenes/Characters/TestRollbackBaseCharacter.tscn")
		map.starting_player_info.append(
			[character_path, id]
		)
		self.change_ui.rpc_id(id)
	
	# get the remaining player slots
	if self.spawn_dummies:
		var remaining_slots = 4 - all_players.size()
		
		# if we have remaining slots, add dummies
		for i in remaining_slots:
			var dummy_path = "Dummy"#load("res://src/Scenes/Characters/Dummy.tscn")
			map.starting_player_info.append(
				[dummy_path, null]
			)
	
	# spawn players and start match
	map.spawn_players()
	
	# give a little time to ping data
	# 3 second delay to allow sync manager to gather ping data to synchronize the start for all clients
	await get_tree().create_timer(3.0).timeout
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
	
	if LOGGING_ENABLED:
		if not DirAccess.dir_exists_absolute(LOG_FILE_DRECTORY):
			DirAccess.make_dir_absolute(LOG_FILE_DRECTORY)
		
		var datetime = Time.get_datetime_dict_from_system(true)
		var log_filename = "%04d%02d%02d-%02d%02d%02d-peer-%d.log" % [
			datetime['year'],
			datetime['month'],
			datetime['day'],
			datetime['hour'],
			datetime['minute'],
			datetime['second'],
			multiplayer.get_unique_id()
		]
		SyncManager.start_logging(LOG_FILE_DRECTORY + "/" + log_filename)
	
	var map = self._get_current_map()
	if map:
		map.start_match()


func _on_sync_stopped():
	if LOGGING_ENABLED:
		SyncManager.stop_logging()


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


func play_map():
	if multiplayer.is_server():
		start_timer.stop()
		var map_scene = load(pick_map())
		if self.vs_CPU:
			self.spawn_dummies = true
		#using call_deferred allows existing map cleanup logic to be called before the scene cleans up
		self._start_map.call_deferred(map_scene)


func pick_map():
	if FORCE_SALOON:
		return "res://src/Scenes/Levels/SaloonMap.tscn"
	if FORCE_CASTLE:
		return "res://src/Scenes/Levels/CastleMap.tscn"
	
	var maps = map_votes.values()
	var peers_count = len(multiplayer.get_peers()) + 1
	if len(maps) != peers_count:
		peers_count -= len(maps)
		for i in range(peers_count):
			var randnumtemp = randi_range(0, map_spawner.get_spawnable_scene_count() - 1)
			maps.append(map_spawner.get_spawnable_scene(randnumtemp))
	var randnum = randi_range(0, len(maps) - 1)
	return maps[randnum]



var time_label_path = "PlayerSelect/MenuButtons/PlayButton/TimeTextHolder/TimeText"
func vote_map_start():
	num_votes += 1
	if start_timer.is_stopped():
		show_timer.rpc()
		update_timer.rpc(start_timeout)
		start_timer.start()
	pass

func cancel_vote_map_start():
	num_votes -= 1
	if num_votes <= 0:
		start_timeout = START_TIMEOUT_MAX
		hide_timer.rpc()
		start_timer.stop()
	pass
	
func _vote_start_timeout():
	if start_timeout > 0:
		start_timeout -= 1
		update_timer.rpc(start_timeout)
		pass
	else:
		start_timer.stop()
		play_map()
		pass
	pass
	
@rpc("any_peer", "call_local", "reliable")
func show_timer():
	var time_label = ui_container.get_node(time_label_path)
	time_label.visible = true
	pass
	
@rpc("any_peer", "call_local", "reliable")
func hide_timer():
	var time_label = ui_container.get_node(time_label_path)
	time_label.visible = false
	pass
	
@rpc("any_peer", "call_local", "reliable")
func update_timer(time_left):
	var time_label = ui_container.get_node(time_label_path)
	time_label.text = str(time_left)
	pass

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

