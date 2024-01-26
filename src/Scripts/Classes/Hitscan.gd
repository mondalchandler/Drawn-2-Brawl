# Chandler Frakes

class_name Hitscan
extends Node

# ---------------- PROPERTIES ----------------- #

# a dictionary to track hit characters from the hitbox
var hit_obj: Node
var relative_ks: Vector3

@export var owner_char: CharacterController
@export var is_chargeable: bool
@export var max_charge: float

# a range of two numbers to indicate what damage rolls the hitbox can have. the second number MUST be greater. integers only
@export var damage_range: Array

# determine how long a character cannot act for when hit, and how long a knockback force is applied
@export var kb_length: float
@export var hitstun_length: float
@export var knockback_strength: Vector3

# determines if hitboxes should show or not
@export var debug_on: bool

# ---------------- FUNCTIONS ---------------- #

func _input(event : InputEvent) -> void:
	if event.is_action_released("normal_far"):
		print("released nf")


# overrideable virtual method.
func _before_hit_computation(hit_char) -> void:
	pass


# overrideable virtual method.
func _after_hit_computation(char, dmg) -> void:
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
	# First we emit the ray scan.
	var space_state = owner_char.get_world_3d().direct_space_state
	var query
	if owner_char.targetting:
		query = PhysicsRayQueryParameters3D.create(owner_char.global_position, owner_char.z_target.global_position)
	else:
		# do the same as the previous clause, except with the direction the character is facing in place of owner_char.z_target.global_position
		if (!owner_char.sprite.flip_h):
			query = PhysicsRayQueryParameters3D.create(owner_char.global_position, owner_char.global_position + Vector3(1000, 0, 1000))
		else:
			query = PhysicsRayQueryParameters3D.create(owner_char.global_position, owner_char.global_position - Vector3(1000, 0, 1000))
	query.exclude = [owner_char]
	var result = space_state.intersect_ray(query)
	self.hit_obj = get_node(result.collider.get_path())
	
	# Here we assess and send the opponent in a direction opposite to the player.
	self.relative_ks.y = self.knockback_strength.y
	if (!owner_char.sprite.flip_h):
		self.relative_ks.x = self.knockback_strength.x - (self.knockback_strength.x * result.normal[0])
		self.relative_ks.z = self.knockback_strength.z - (self.knockback_strength.z * result.normal[2])
	else:
		self.relative_ks.x = self.knockback_strength.x + (self.knockback_strength.x * result.normal[0])
		self.relative_ks.z = self.knockback_strength.z + (self.knockback_strength.z * result.normal[2])
	
	# Then we apply the appropriate effect.
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
func _process(delta):
	pass

# ---------------- INIT ---------------- #

func _init(hit_obj = null, owner_char = null, is_chargeable = false, max_charge = 0, damage_range = [0, 0], kb_length = 0, hitstun_length = 0, knockback_strength = Vector3.ZERO, relative_ks = Vector3.ZERO, debug_on = false):
	self.hit_obj = hit_obj
	self.owner_char = owner_char
	self.is_chargeable = is_chargeable
	self.max_charge = max_charge
	self.damage_range = damage_range
	self.kb_length = kb_length
	self.hitstun_length = hitstun_length
	self.knockback_strength = knockback_strength
	self.relative_ks = relative_ks
	self.debug_on = debug_on
