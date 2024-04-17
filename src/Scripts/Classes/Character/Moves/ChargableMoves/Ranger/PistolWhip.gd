# Kyle Senebouttarath

extends Move

# ---------------------------------------- CONSTANTS ------------------------------------------ #

const SPEED_SLOWDOWN : float = 10.0

# ---------------------------------------- NODES ------------------------------------------ #

@onready var cooldown_timer : NetworkTimer = $CooldownTimer
@onready var hitbox_spawn_timer : NetworkTimer = $HitboxSpawnTimer
@onready var move_end_timer : NetworkTimer = $MoveEndTimer

# ---------------------------------------- PROPERTIES ------------------------------------------ #

var on_cooldown : bool = false

# ---------------------------------------- MAIN FUNCTIONS ------------------------------------------ #

# this function is called on every rollback network update
func move_update(input_down : bool) -> void:
	if not self.char: return
	if not input_down: return
	if input_down and self.on_cooldown: return
	if self.char.performing > 0: return
	
	self.on_cooldown = true
	self.char.performing += 1
	self.char.autorotate += 1
	
	cooldown_timer.start()
	hitbox_spawn_timer.start()
	move_end_timer.start()
	
	self.char.play_action_anim("pistol_whip")
	self.char.speed /= SPEED_SLOWDOWN

# ---------------------------------------- CONNECTIONS ------------------------------------------ #

func _on_cooldown_timeout():
	self.on_cooldown = false

func _on_move_end_timer_timeout():
	self.char.speed *= SPEED_SLOWDOWN
	self.char.performing -= 1
	self.char.autorotate -= 1

func _on_hitbox_spawn_timer_timeout():
	#self.char.performing_val -= 1
	pass # Replace with function body.

# ---------------------------------------- ROLLBACK FUNCTIONS ------------------------------------------ #

func _network_process(_input: Dictionary) -> void:
	pass

func _save_state() -> Dictionary:
	return {
		on_cooldown = self.on_cooldown,
	}

func _load_state(state: Dictionary) -> void:
	self.on_cooldown = state["on_cooldown"]
