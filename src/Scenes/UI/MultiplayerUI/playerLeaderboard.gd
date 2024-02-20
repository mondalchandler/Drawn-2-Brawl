# Kyles45678

extends Node

#----------------- CONTENTS -----------------#

@onready var titleLabel : Label = $CanvasLayer/PanelContainer/GridContainer/TitleLabel
@onready var playerLabel : Label = $CanvasLayer/PanelContainer/GridContainer/PlayerLabel
@onready var playerList : GridContainer = $CanvasLayer/PanelContainer/PlayerList
@onready var canvasLayer : CanvasLayer = $CanvasLayer

#----------------- GLOBALS -----------------#

var players : Dictionary = {}

#----------------- METHODS -----------------#


func toggle_visible(visible : bool):
	canvasLayer.visible = visible


func _update_ui():
	for n in playerList.get_children():
		if n != titleLabel:
			playerList.remove_child(n)
			
	for playerId in players:
		var newNode = playerLabel.duplicate()
		newNode.text = "Player " + playerId
		if players[playerId] == "Host":
			newNode.text += " (Host)"
		else:
			newNode.text += " (Client)"
		playerList.add_child(newNode)


func add_player(playerId : int, isHost : bool):
	if not players[playerId]:
		players[playerId] = "Host" if isHost else "Client"
	self._update_ui()


func remove_player(playerId : int):
	if players[playerId]:
		players.erase(playerId)
	self._update_ui()


func _ready():
	toggle_visible(false)
	self._update_ui()

