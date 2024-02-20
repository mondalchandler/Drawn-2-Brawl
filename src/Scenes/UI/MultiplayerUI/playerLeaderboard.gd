# Kyles45678

extends Node

#----------------- CONTENTS -----------------#

@onready var canvasLayer : CanvasLayer = $CanvasLayer

@onready var lobbyLabel : Label = $CanvasLayer/Main/Content/LobbyInfo/LobbyName

@onready var playerList : GridContainer = $CanvasLayer/Main/Content/PlayerList
@onready var playerLabel : Label = $CanvasLayer/Main/Content/PlayerList/PlayerLabel

#----------------- GLOBALS -----------------#

var players : Dictionary = {}

#----------------- METHODS -----------------#


func toggle_visible(visible : bool):
	canvasLayer.visible = visible


func update_ui():
	for n in playerList.get_children():
		playerList.remove_child(n)
			
	for playerId in players:
		var newNode = playerLabel.duplicate()
		newNode.text = "Player " + str(playerId)
		if players[playerId] == "Host":
			newNode.text += " (Host)"
		else:
			newNode.text += " (Client)"
		playerList.add_child(newNode)
	


func add_player(playerId : int, isHost : bool):
	if not players.has(playerId):
		players[playerId] = "Host" if isHost else "Client"
	self.update_ui()


func remove_player(playerId : int):
	if players.has(playerId):
		players.erase(playerId)
	self.update_ui()


func set_lobby_name(lobbyName : String):
	lobbyLabel.text = lobbyName


func _ready():
	toggle_visible(false)
	self.update_ui()

