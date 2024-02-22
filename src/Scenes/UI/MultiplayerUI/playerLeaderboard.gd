# Kyles45678

extends Node

#------------------------------------------ GAME ---------------------------------------#

# used to change from scene to scene
@onready var main_scene = get_tree().root.get_node("main_scene")

# used to show server connections 
@onready var players = main_scene.get_node("Players")

#------------------------------------------ CONTENTS ---------------------------------------#

@onready var canvasLayer : CanvasLayer = $CanvasLayer

@onready var lobbyLabel : Label = $CanvasLayer/Main/Content/LobbyInfo/LobbyName

@onready var playerList : GridContainer = $CanvasLayer/Main/Content/PlayerList
@onready var playerLabel : Label = $CanvasLayer/Main/Content/PlayerList/PlayerLabel

#------------------------------------------- GLOBALS -------------------------------------#

var leaderboard_players : Dictionary = {}

#------------------------------------------ METHODS --------------------------------------------#


func toggle_visible(visible : bool):
	canvasLayer.visible = visible


func _create_player_label(text : String, id : int):
	var text_color = Color(1, 1, 1)
	if multiplayer.get_unique_id() == id:
		text_color = Color(0, 1, 0.25)
	
	var newNode = playerLabel.duplicate()
	newNode.text = text
	newNode.add_theme_color_override("font_color", text_color)
	playerList.add_child(newNode)


func update_ui():
	for n in playerList.get_children():
		playerList.remove_child(n)
	
	for playerId in leaderboard_players:
		if leaderboard_players[playerId] == "Host":
			self._create_player_label("Player " + str(playerId) + " (Host)", playerId)
	
	for playerId in leaderboard_players:
		if leaderboard_players[playerId] != "Host":
			self._create_player_label("Player " + str(playerId) + " (Client)", playerId)


func add_player(playerId : int, is_host : bool):
	if not leaderboard_players.has(playerId):
		leaderboard_players[playerId] = "Host" if is_host else "Client"
	self.update_ui()


func _on_player_disconnected(playerId : int):
	if leaderboard_players.has(playerId):
		leaderboard_players.erase(playerId)
	self.update_ui()


func set_lobby_name(lobbyName : String):
	lobbyLabel.text = lobbyName


func _on_player_connected(id : int, player_info):
	self.add_player(id, id == 1)
	toggle_visible(true)


func _on_server_close():
	leaderboard_players.clear()
	self.toggle_visible(false)
	self.update_ui()


func _ready():
	toggle_visible(false)
	self.update_ui()
	
	players.connect("player_connected", self._on_player_connected)
	players.connect("player_disconnected", self._on_player_disconnected)
	players.connect("server_disconnected", self._on_server_close)

