# Kyle Senebouttarath

extends Move

# ---------------------------------------- PROPERTIES ------------------------------------------ #

var char : RollbackCharacterController = null

# ---------------------------------------- FUNCTIONS ------------------------------------------ #

# this function is called on every rollback network update
func move_update(input_down : bool) -> void:
	pass

# this function is called on when the move controller runs _ready, but it sends the using character to this move file
func move_ready(set_char : RollbackCharacterController) -> void:
	self.char = set_char
