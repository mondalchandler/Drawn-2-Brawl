# Chandler Frakes

# << !!!! NOT BEING USED ATM, ALSO CHARGE FUNCTIONALITY INCOMPLETE !!!! >>

# HOW TO ADD CUSTOM HITSCAN
	# 1) Add Hitscan child node to Hurtbox
	# 2) Fill out corresponding variables to how you want strength, kb, stun to act
	# 3) In the corresponding Move node, assign this Hitscan node to the corresponding variable
	# 4) Use the shoot_once variable in AnimationPlayer to activate the hitscan

class_name Hitscan
extends Node

# ---------------- PROPERTIES ----------------- #

var hit_obj: Node
var relative_ks: Vector3

@export var owner_char: CharacterController
@export var is_chargeable: bool
@export var max_charge: float
@export var shoot_once: bool

# a range of two numbers to indicate what damage rolls the hitbox can have. the second number MUST be greater. integers only
@export var damage_range: Array

# determine how long a character cannot act for when hit, and how long a knockback force is applied
@export var kb_length: float
@export var hitstun_length: float
@export var knockback_strength: Vector3

# determines if hitboxes should show or not
@export var debug_on: bool

# ---------------- FUNCTIONS ---------------- #

func _calc_kb_vector():
	if (owner_char.sprite.flip_h):		# if we are facing left
		if (self.knockback_strength.x > 0 && self.knockback_strength.z > 0):	# if the move magnitude is rightward, make it face left
			self.knockback_strength *= Vector3(-1, 1, -1)
	else:					# else we are facing right
		if (self.knockback_strength.x < 0 && self.knockback_strength.z < 0):	# if the move magnitude is leftward, make it face right
			self.knockback_strength *= Vector3(-1, 1, -1)
			


func _input(event : InputEvent) -> void:
	if event.is_action_released("normal_far"):
		pass


# overrideable virtual method.
func _before_hit_computation(_hit_char) -> void:
	pass


# overrideable virtual method.
func _after_hit_computation(_character, _dmg) -> void:
	pass


func deal_stun(hit_char) -> void:
	hit_char.can_move = false
	var stun_tween = hit_char.get_tree().create_tween()
	stun_tween.tween_property(hit_char, "can_move", true, hitstun_length)


func deal_kb(hit_char) -> void:
	hit_char.knockback = relative_ks
	var knockback_tween = hit_char.get_tree().create_tween()
	knockback_tween.tween_property(hit_char, "knockback", Vector3.ZERO, kb_length)


# computes a damage value, then updates an enemy char's hp value
func deal_dmg(hit_char) -> int:
	if not hit_char.invincible:
		var dmg = randi() % (self.damage_range[1] - self.damage_range[0] + 1) + self.damage_range[0]
		var new_hp = hit_char.health - dmg
		if new_hp < 0:
			new_hp = 0
		hit_char.health = new_hp
		return dmg
	else:
		return 0


func on_hit(hit_char) -> void:
	self._before_hit_computation(hit_char)
	
	# deal values to character
	self.deal_stun(hit_char)
	self.deal_kb(hit_char)
	var dmg = self.deal_dmg(hit_char)
	
	self._after_hit_computation(hit_char, dmg)


func shoot():
	var space_state = owner_char.get_world_3d().direct_space_state
	var query = get_ray_query()
	query.exclude = [owner_char]
	var result = space_state.intersect_ray(query)
	self.hit_obj = get_node(result.collider.get_path())
	assess_opponent_direction(result)
	apply_effect()


# First we emit the ray scan.
func get_ray_query():
	if owner_char.targetting:
		return PhysicsRayQueryParameters3D.create(owner_char.global_position, owner_char.z_target.global_position)
	else:
		if (!owner_char.sprite.flip_h):
			return PhysicsRayQueryParameters3D.create(owner_char.global_position, owner_char.global_position + Vector3(1000, 0, 1000))
		else:
			return PhysicsRayQueryParameters3D.create(owner_char.global_position, owner_char.global_position - Vector3(1000, 0, 1000))


# Here we assess and send the opponent in a direction opposite to the player.
# ONLY HAPPENS WHEN TARGETTING IS ON
func assess_opponent_direction(result):
	_calc_kb_vector()
	self.relative_ks.y = self.knockback_strength.y
	if (!owner_char.sprite.flip_h):
		self.relative_ks.x = self.knockback_strength.x - (self.knockback_strength.x * result.normal[0])
		self.relative_ks.z = self.knockback_strength.z - (self.knockback_strength.z * result.normal[2])
	else:
		self.relative_ks.x = self.knockback_strength.x + (self.knockback_strength.x * result.normal[0])
		self.relative_ks.z = self.knockback_strength.z + (self.knockback_strength.z * result.normal[2])


# Then we apply the appropriate effect.
func apply_effect():
	if (self.node_is_object(hit_obj)):
		self.hit_obj.get_node("Destruction").destroy()
	elif (hit_obj is CharacterController):
		on_hit(hit_obj)


func node_is_object(node):
	return node.get_node_or_null("Destruction") != null


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (self.shoot_once):
		shoot()
		self.shoot_once = false

# ---------------- INIT ---------------- #

func _init(new_hit_obj = null, new_owner_char = null, new_is_chargeable = false, new_max_charge = 0, 
	new_damage_range = [0, 0], new_kb_length = 0, new_hitstun_length = 0, new_knockback_strength = Vector3.ZERO, 
	new_relative_ks = Vector3.ZERO, new_debug_on = false, new_shoot_once = false):
		
	self.hit_obj = new_hit_obj
	self.owner_char = new_owner_char
	self.is_chargeable = new_is_chargeable
	self.max_charge = new_max_charge
	self.damage_range = new_damage_range
	self.kb_length = new_kb_length
	self.hitstun_length = new_hitstun_length
	self.knockback_strength = new_knockback_strength
	self.relative_ks = new_relative_ks
	self.debug_on = new_debug_on
	self.shoot_once = new_shoot_once
