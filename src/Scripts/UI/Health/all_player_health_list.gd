# Kyle Senebouttarath

extends Control

# ---------------- GLOBALS ---------------- #

@onready var mainUI = $"."
@onready var barList = $MarginContainer/HBoxContainer

var healthBar = preload("res://src/Scenes/UI/Health/health_bar.tscn")
var trackingPlayersDict = {}

# ---------------- FUNCTIONS ---------------- #


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for character in trackingPlayersDict:
		trackingPlayersDict[character].value = (character.health / character.max_health) * 100.0


func on_add_player_to_ui(character):
	var newHealthBar = healthBar.instantiate()
	var charName = character.display_name
	
	newHealthBar.get_node("PlayerName").text = charName
	barList.add_child(newHealthBar)
	trackingPlayersDict[character] = newHealthBar.get_node("Bar")


# ---------------- INPUT FUNCTIONS ---------------- #


# ---------------- INIT ---------------- #

# Creates a signal named "add_player" to this node
signal add_player

# Called when the node enters the scene tree for the first time.
func _ready():
	mainUI.connect("add_player", on_add_player_to_ui)

