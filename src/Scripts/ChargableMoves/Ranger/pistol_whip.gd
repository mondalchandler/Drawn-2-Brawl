extends Move


@export var max_damage: int = 30
@export var charge_time: int = 5

var damage_range_holder = [0, 0]
var time_passed = 0


func move_charge_effect(delta):
	time_passed+=delta
	if time_passed < charge_time:
		self.hitbox.damage_range[1] = (time_passed/charge_time)*(max_damage-damage_range_holder[1]) + damage_range_holder[1]
		self.hitbox.damage_range[0] = (time_passed/charge_time)*(max_damage-damage_range_holder[0]) + damage_range_holder[0]
	else:
		get_node("../../Twinkle").visible = true


func move_reset():
	self.hitbox.damage_range[0] = self.damage_range_holder[0]
	self.hitbox.damage_range[1] = self.damage_range_holder[1]
	time_passed=0
	get_node("../../Twinkle").visible = false


func _ready():
	self.damage_range_holder[0] = self.hitbox.damage_range[0]
	self.damage_range_holder[1] = self.hitbox.damage_range[1]
