# Kyle Senebouttarath
# This script will set up a client-server networking modal for the game

# ------------------------------- IMPORTS --------------------------------- #

extends Node

# ------------------------------- SCENE ELEMENTS --------------------------------- #

# used to change from scene to scene
@onready var main_scene = get_tree().root.get_node("main_scene")

# used to show server connections 
@onready var leaderboard = main_scene.get_node("PlayerLeaderboard")

# elements for the server control panel
@onready var createLobbyNameField = $CanvasLayer/LobbyCreatePanel/Main/MiddleContent/NameField
@onready var createLobbyPortField = $CanvasLayer/LobbyCreatePanel/Main/MiddleContent/PortField
@onready var createLobbyMaxPlayersField = $CanvasLayer/LobbyCreatePanel/Main/MiddleContent/MaxPlayersField
@onready var createLobbyButton = $CanvasLayer/LobbyCreatePanel/Main/CreateButton

#elements for the client control panel
@onready var joinLobbyIPField = $CanvasLayer/LobbyJoinPanel/Main/MiddleContent/LobbyIPField
@onready var joinLobbyPortField = $CanvasLayer/LobbyJoinPanel/Main/MiddleContent/PortField
@onready var joinLobbyPlayerNameField = $CanvasLayer/LobbyJoinPanel/Main/MiddleContent/PlayerNameField
@onready var joinLobbyButton = $CanvasLayer/LobbyJoinPanel/Main/JoinButton

# ------------------------------- SERVER NETWORKING FUNCTIONS --------------------------------- #

func createLobby(port : int, maxPlayers : int, lobbyName : String):
	print("Creating new lobby...")
	
	# create a server for the lobby
	var host = ENetMultiplayerPeer.new()
	host.create_server(port, maxPlayers)
	#lobby.lobby_name = lobbyName
	multiplayer.set_multiplayer_peer(host)
	
	# update UI
	leaderboard.add_player(host.get_unique_id(), true)
	leaderboard.set_lobby_name(lobbyName)
	showLeaderboard()


func playerClientJoined(peer_id: int):
	print(3, peer_id)
	leaderboard.add_player(peer_id, false)


func playerClientRemoved(peer_id: int):
	print(4, peer_id)
	leaderboard.remove_player(peer_id)


# ------------------------------- CLIENT NETWORKING FUNCTIONS --------------------------------- #

func joinLobby(lobbyIP : String, lobbyPort : int, playerName : String):
	print("Joining a lobby...")
	# create new client peer
	var player = ENetMultiplayerPeer.new()
	player.create_client(lobbyIP, lobbyPort)
	#print(player)
	#player.player_name = playerName
	multiplayer.set_multiplayer_peer(player)
	
	# update UI
	leaderboard.add_player(player.get_unique_id(), false)
	showLeaderboard()


func connectedToServer():
	print(1)
	var peer_id = multiplayer.get_unique_id()
	leaderboard.add_player(peer_id, false)

	#players[peer_id] = player_info
	#player_connected.emit(peer_id, player_info)
	pass


func disconnectedFromServer():
	print(2)
	pass


func connectionFailed():
	print("I FAILED FUCK FACE!")

# ------------------------------- UI FUNCTIONS --------------------------------- #

func onCreateButtonPressed():
	var lobbyPort = int(createLobbyPortField.text)
	var lobbyMaxPlayers = int(createLobbyMaxPlayersField.text)
	var lobbyName = createLobbyNameField.text
	self.createLobby(lobbyPort, lobbyMaxPlayers, lobbyName)
	main_scene._change_scene("res://src/Scenes/UI/player_select.tscn")


func onJoinButtonPressed():
	var lobbyIP = joinLobbyIPField.text
	var lobbyPort = int(joinLobbyPortField.text)
	var playerName = joinLobbyPlayerNameField.text
	self.joinLobby(lobbyIP, lobbyPort, playerName)
	main_scene._change_scene("res://src/Scenes/UI/player_select.tscn")


func showLeaderboard():
	leaderboard.toggle_visible(true)

# ------------------------------- GODOT FUNCTIONS --------------------------------- #

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# --------- FUNCTION CONNECTIONS --------- #
	createLobbyButton.pressed.connect(self.onCreateButtonPressed)
	joinLobbyButton.pressed.connect(self.onJoinButtonPressed)
	
	# set up events for players joining and leaving the lobby
	multiplayer.peer_connected.connect(self.playerClientJoined)
	multiplayer.peer_disconnected.connect(self.playerClientRemoved)
	
	# set up events for when our client joins the lobby server
	multiplayer.connected_to_server.connect(self.connectedToServer)
	multiplayer.server_disconnected.connect(self.disconnectedFromServer)
	multiplayer.connection_failed.connect(self.connectionFailed)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
