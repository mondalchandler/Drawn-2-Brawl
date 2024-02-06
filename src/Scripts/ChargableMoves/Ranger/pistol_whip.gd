extends Move


var damage_range_holder = [0, 0]
@export var max_damage: int = 30
@export var charge_time: int = 5
var time_passed = 0


func move_charge_effect(delta):
	time_passed+=delta
	if time_passed < charge_time:
		self.hitbox.damage_range[1] = (time_passed/charge_time)*(max_damage-damage_range_holder[1]) + damage_range_holder[1]
		self.hitbox.damage_range[0] = (time_passed/charge_time)*(max_damage-damage_range_holder[0]) + damage_range_holder[0]
	pass
	
func move_reset():
	self.hitbox.damage_range[0] = self.damage_range_holder[0]
	self.hitbox.damage_range[1] = self.damage_range_holder[1]
	time_passed=0
	pass

func _ready():
	self.damage_range_holder[0] = self.hitbox.damage_range[0]
	self.damage_range_holder[1] = self.hitbox.damage_range[1]
