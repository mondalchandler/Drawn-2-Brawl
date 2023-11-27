# Kyle Senebouttarath

# ----------------- IMPORTS ------------------ #

extends PanelContainer

# ----------------- GLOBALS ------------------ #

@onready var player_name_label = $MarginContainer/Details/PlayerName
@onready var ranking_label = $MarginContainer/Details/Ranking

var player_name: String = "<player name>"
var placement: int = 999

# ----------------- FUNCTIONS ------------------ #

func number_to_place(place: int):
	if place == 1:
		return "FIRST"
	elif place == 2:
		return "SECOND"
	elif place == 3:
		return "THIRD"
	elif place == 4:
		return "FOURTH"
		
	return "NO CONTEST"


# Called when the node enters the scene tree for the first time.
func _ready():
	player_name_label.text = player_name
	ranking_label.text = number_to_place(placement)

