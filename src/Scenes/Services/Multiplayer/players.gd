# Kyle Senebouttarath
# This class is intended to handle all of the major networking functionality.
# It should be reponsible for tracking player/character data for the lobby session they are in

# ---------------------------------------------------- IMPORTS ------------------------------------------ #

extends Node
class_name Players

# --------------------------------------------------- SIGNALS ---------------------------------------------------- #

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

# ------------------------------------------------------ PROPERTIES ------------------------------------------ #

@export var lobby_name : String = "<lobby name>"
@export var max_players : int = 4

# this will contain player info for every player, with the keys being each peer unique IDs
var players = {}

# This is the local player info. This should be modified locally before the connection is made. 
# It will be passed to every other peer.
# For example, the value of "name" can be set to something the player entered in a UI scene.
var player_info = {
	"name" : "SampleName",
	"selected_character" : "Ranger",
}

# indicator of number of players that are in the lobby
var players_loaded = 0

# ---------------------------------------------- INIT --------------------------------------------- #

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# these are client events (i think)
	multiplayer.peer_connected.connect(self._on_player_connected)
	multiplayer.peer_disconnected.connect(self._on_player_disconnected)
	
	# these are server events
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ----------------------------------------------- SERVER RPCS ----------------------------------------------- #

# a remote procedure call that gets used to add a new player into our players dictionary, along with any information we need
# the "any_peer" mode indicates that clients are allowed to call this remotely (send data to the server)
# the "reliable" property indicates to use a TCP protocol to send the data
# this code runs on the server! think of it as an receiving event connection to a "rpc_id" call
@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	
	# this get's the peer id of the client who is sending the RPC.
	var new_player_id = multiplayer.get_remote_sender_id()
	
	# track new player in players table
	players[new_player_id] = new_player_info
	
	# emit signal of new player added and their player information
	player_connected.emit(new_player_id, new_player_info)

# ----------------------------------------------- CLIENT METHODS ----------------------------------------------- #

# when a new client peer connects, the client will send them their player info.
# this allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id : int) -> void:
	_register_player.rpc_id(id, player_info)


# when the current client disconnects, remove them from the players table and emit a signal
func _on_player_disconnected(id : int) -> void:
	players.erase(id)
	player_disconnected.emit(id)

# disconnects the client from the current server they're connected to
func disconnect_client():
	var peer_id = multiplayer.get_unique_id()
	self._on_player_disconnected(peer_id)
	server_disconnected.emit()
	multiplayer.multiplayer_peer = null

# ----------------------------------------------- SERVER METHODS ----------------------------------------------- #

# creates a new lobby by setting this player as a host on a specified IP
func create_lobby(port : int, max_players : int, lobby_name : String) -> void:

	# create a server for the lobby
	var host = ENetMultiplayerPeer.new()
	var error = host.create_server(port, max_players)
	if error:
		print("Create Lobby Error Code: ", error)
		return
	
	# set the multiplayer peer
	multiplayer.set_multiplayer_peer(host)
	multiplayer.multiplayer_peer = host
	
	# add their player information
	players[1] = player_info
	player_connected.emit(1, player_info)

# joins a exsiting lobby
func join_lobby(lobby_ip : String, lobby_port : int, player_name : String) -> void:
	# fallback IP
	if lobby_ip.is_empty():
		lobby_ip = "localhost"
	
	# create new client peer
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(lobby_ip, lobby_port)
	if error:
		print("Join Lobby Error Code: ", error)
		return
	
	# set the peer
	multiplayer.set_multiplayer_peer(peer)
	multiplayer.multiplayer_peer = peer


# if a client connected successfully to the server, give them some info
func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


# if a client failed to connect, set their connection off
func _on_connected_fail():
	multiplayer.multiplayer_peer = null


# if the server host closes the game, clear all the game information
func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()


# goes through all the peers and disconnects other clients first
func shutdown_server():
	for peer_id in players:
		if peer_id != 1:
			players.erase(peer_id)
			player_disconnected.emit(peer_id)
	self._on_server_disconnected()




