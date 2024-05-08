# Kyle Senebouttarath
# This script will set up a client-server networking modal for the game

# ------------------------------- IMPORTS --------------------------------- #

extends Node

# ------------------------------- SCENE ELEMENTS --------------------------------- #

# used to change from scene to scene
@onready var main_scene = get_tree().root.get_node("main_scene")

# players service 
@onready var players = main_scene.get_node("Players")

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

#elements for the offline play control panel
@onready var offlineLobbyNumPlayersField = $CanvasLayer/LobbyOfflinePanel/Main/MiddleContent/NumPlayersField
@onready var offlineLobbyStartButton = $CanvasLayer/LobbyOfflinePanel/Main/StartButton

# ------------------------------- UI FUNCTIONS --------------------------------- #

func onCreateButtonPressed():
	var lobbyPort = int(createLobbyPortField.text)
	var lobbyMaxPlayers = int(createLobbyMaxPlayersField.text)
	var lobbyName = createLobbyNameField.text
	players.create_lobby(lobbyPort, lobbyMaxPlayers, lobbyName)
	main_scene.change_ui("res://src/Scenes/UI/player_select.tscn")


func onJoinButtonPressed():
	var lobbyIP = joinLobbyIPField.text
	var lobbyPort = int(joinLobbyPortField.text)
	var playerName = joinLobbyPlayerNameField.text
	players.join_lobby(lobbyIP, lobbyPort, playerName)
	main_scene.change_ui("res://src/Scenes/UI/player_select.tscn")


func onOfflineButtonPressed():
	var numberOfflinePlayers = int(offlineLobbyNumPlayersField.text)
	players.create_offline_lobby(numberOfflinePlayers)
	main_scene.change_ui("res://src/Scenes/UI/player_select.tscn")


# ------------------------------- GODOT FUNCTIONS --------------------------------- #

# Called when the node enters the scene tree for the first time.
func _ready():
	createLobbyButton.pressed.connect(self.onCreateButtonPressed)
	joinLobbyButton.pressed.connect(self.onJoinButtonPressed)
	offlineLobbyStartButton.pressed.connect(self.onOfflineButtonPressed)


