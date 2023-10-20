# Kyle Senebouttarath

extends Control

# ---------------- GLOBALS ---------------- #

@onready var mainUI = $"."
@onready var barList = $MarginContainer/HBoxContainer

var healthBar = load("res://src/Scenes/UI/health_bar.tscn")
var trackingPlayersDict = {}

# ---------------- FUNCTIONS ---------------- #


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for character in trackingPlayersDict:
		var curHealth = character.get_meta("Health")
		var maxHealth = character.get_meta("MaxHealth")
		
		trackingPlayersDict[character].value = (curHealth / maxHealth) * 100.0
		


func on_add_player_to_ui(character):
	var newHealthBar = healthBar.instantiate()
	var charName = character.get_name()
	
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

