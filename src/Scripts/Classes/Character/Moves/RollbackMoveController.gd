# Chandler Frakes, Kyle Senebouttarath, Alex Ottelien

# --------------------------------------- IMPORTS ------------------------------------------- #

class_name RollbackMoveController
extends Node

# ---------------------------------------- CONSTANTS ------------------------------------------ #

const INPUT_TO_ABBREVIATION = {
	normal_close = "nc",
	normal_far = "nf",
	special_close = "sc",
	special_far = "sf",
}

const MOVE_NAMES = [
	"ground_nc", "ground_nf", "ground_sc", "ground_sf",
	"air_nc", "air_nf", "air_sc", "air_sf",
]

# ---------------------------------------- PROPERTIES ------------------------------------------ #

@onready var char : RollbackCharacterController = $".."

# variables used to track the moves currently loaded onto our character
@export var ground_nc: RollbackMove = null
@export var ground_nf: RollbackMove = null
@export var ground_sc: RollbackMove = null
@export var ground_sf: RollbackMove = null
@export var air_nc: RollbackMove = null
@export var air_nf: RollbackMove = null
@export var air_sc: RollbackMove = null
@export var air_sf: RollbackMove = null

# ---------------------------------------- FUNCTIONS ------------------------------------------ #

func on_update(input_name : String, input_state : bool, on_floor : bool):
	# construct a string to indicate the move we're using
	var airborne_state = "ground" if on_floor else "air"
	var move_type = INPUT_TO_ABBREVIATION.get(input_name, "")
	var move_name = airborne_state + "_" + move_type
	
	# if our move doesn't exist, we dont continue
	if move_type == "" or not self[move_name]:
		return
	
	# call the move's update function
	if self[move_name]["move_update"]:
		self[move_name].move_update(input_state)


func _ready():
	self.char = $".."
	
	for move_name in MOVE_NAMES:
		if self[move_name] and self[move_name]["move_ready"]:
			self[move_name].move_ready(self.char)
