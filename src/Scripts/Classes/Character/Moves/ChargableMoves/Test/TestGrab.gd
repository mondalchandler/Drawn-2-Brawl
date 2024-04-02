# Kyle Senebouttarath

extends RollbackMove

# ---------------------------------------- CONSTANTS ------------------------------------------ #

const GRAB_RANGE = 2

# ---------------------------------------- NODES ------------------------------------------ #

@onready var grab_cooldown : NetworkTimer = $GrabCooldownDebounce

var char : RollbackCharacterController = null
var grabbing_character : RollbackCharacterController = null

# ---------------------------------------- PROPERTIES ------------------------------------------ #

var can_grab : bool = true

# ---------------------------------------- FUNCTIONS ------------------------------------------ #

func grab_char(target_char : RollbackCharacterController) -> void:
	char.grabbing_player = target_char
	char.grabbing = true
	target_char.being_grabbed = true
	self.grabbing_character = target_char


func ungrab() -> void:
	if self.grabbing_character:
		self.grabbing_character.being_grabbed = false
	char.grabbing = false
	char.grabbing_player = null
	self.grabbing_character = null


# this function is called on every rollback network update
func move_update(input_down : bool) -> void:
	if not self.char: return
	if not self.can_grab:
		return
	
	if input_down:
		if not char.grabbing:
			self.hitbox.active = true
			var closest_data = char.get_closest_player()
			var target_char = closest_data[0]
			var target_dist = closest_data[1]
			if target_char and not target_char.being_grabbed and target_dist <= GRAB_RANGE :
				self.grab_char(target_char)
		else:
			self.hitbox.active = false
			self.ungrab()
		
		self.can_grab = false
		grab_cooldown.start()


# this function is called on when the move controller runs _ready, but it sends the using character to this move file
func move_ready(set_char : RollbackCharacterController) -> void:
	self.char = set_char


func _on_grab_cooldown_debounce_timeout():
	self.can_grab = true


func _network_process(_input: Dictionary) -> void:
	pass


func _save_state() -> Dictionary:
	return {
		can_grab = self.can_grab,
		hitbox = self.hitbox
	}


func _load_state(state: Dictionary) -> void:
	self.can_grab = state["can_grab"]
	self.hitbox = state["hitbox"]
