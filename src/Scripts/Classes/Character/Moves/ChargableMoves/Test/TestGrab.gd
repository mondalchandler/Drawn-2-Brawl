# Kyle Senebouttarath

extends RollbackMove

# ---------------------------------------- CONSTANTS ------------------------------------------ #

const GRAB_RANGE = 2

# ---------------------------------------- NODES ------------------------------------------ #

@onready var grab_cooldown : NetworkTimer = $GrabCooldownDebounce
@onready var axe_hitbox : RollbackHitbox = $"../../Hurtbox/Axe Uppercut Hitbox"

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
	if (char.sprite.flip_h): # if we are facing left
		char.hurtbox.rotation.y = PI
	else: # else we are facing right
		char.hurtbox.rotation.y = 0
	if input_down:
		self.axe_hitbox.active = true


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
	}


func _load_state(state: Dictionary) -> void:
	self.can_grab = state["can_grab"]
