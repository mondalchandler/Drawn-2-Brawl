# Kyles45678
# This class is the base class for a hitbox in the game. 

# ---------------- IMPORTS ------------------- #

class_name BaseHitbox
extends Area3D

# ---------------- PROPERTIES ----------------- #

# nodes used for the hitbox
var collision_shape: CollisionShape3D
var mesh_instance: MeshInstance3D	# for hitbox visuals

# the original character object, creator of the hitbox. can be null
var owner_char

# a range of two numbers to indicate what damage rolls the hitbox can have. the second number MUST be greater. integers only
var damage_range: Array

# a dictionary to track hit characters from the hitbox
var hit_chars: Dictionary

# the positional offset of the hitbox, RELATIVE to the character's pivot (center transform)
var origin_offset: Transform3D

# determine how long a character cannot act for when hit, and how long a knockback force is applied
var hitstun_length: float
var kb_length: float

# determines if hitboxes should show or not
var debug_on: bool

# ------------------- METHODS --------------------- #

# constructor
func _init(char, offset: Transform3D, dmg_rng: Array, hitstun: float, kb_len: float) -> void:
	self.owner_char = char
	
	self.origin_offset = offset if (offset != null) else Transform3D.IDENTITY
	self.damage_range = dmg_rng if (dmg_rng != null) else [5, 5]
	self.hitstun_length = hitstun if (hitstun != null) else 0.5
	self.kb_length = kb_len if (kb_len != null) else 0.2
	
	self.hit_chars = {}
	self.name = "Hitbox"
	self.debug_on = false
	self.monitoring = false


func set_debug_mode(state: bool) -> void:
	self.debug_on = state


# turns on hitbox monitoring and refreshes hit character dictionary
func _activate() -> void:
	self.hit_chars = {}
	self.monitoring = true
	if self.debug_on == true and self.mesh_instance != null:
		self.mesh_instance.visible = true


# turns off monitoring, refreshes the queue
func _deactivate() -> void:
	self.monitoring = false
	self.hit_chars = {}
	if self.mesh_instance != null:
		self.mesh_instance.visible = false


# TODO: this function will make use of the owner character node, the enemy character node,
	# and the hitbox node to determine a vector3 for knockback velocity 
func _calc_kb_vector(enemChar) -> Vector3:
	return Vector3.ZERO


# determines if a hit node is a character. chars have hurtboxes and health
func node_is_char(node) -> bool:
	return node.get_node_or_null("Hurtbox") != null and node.get_meta("Health") and node.get_meta("MaxHealth")


# overrideable virtual method.
func _before_hit_computation(hit_char) -> void:
	pass


# overrideable virtual method.
func _after_hit_computation(char, dmg) -> void:
	pass


# TODO: Implement stun system
func deal_stun(hit_char) -> void:
	# make it so that the hit_char cannot move for 3 seconds (hit_char.can_move = false)
	hit_char.can_move = false
	var stun_tween = hit_char.get_tree().create_tween()
	stun_tween.tween_property(hit_char, "can_move", true, 3.0)


# TODO: Implement knockback system
func deal_kb(hit_char) -> void:
	var knockback_strength : Vector3 = Vector3(10, 10, 10)
	hit_char.knockback = knockback_strength
	var knockback_tween = hit_char.get_tree().create_tween()
	knockback_tween.tween_property(hit_char, "knockback", Vector3.ZERO, 0.25)


# computes a damage value, then updates an enemy char's hp value
func deal_dmg(hit_char) -> int:
	var dmg = randi() % (self.damage_range[1] - self.damage_range[0] + 1) + self.damage_range[0]
	var new_hp = hit_char.get_meta("Health") - dmg
	if new_hp < 0:
		new_hp = 0
	hit_char.set_meta("Health", new_hp)
	return dmg


func on_hit(hit_char) -> void:
	# NOTES FOR FUTURE, we will probs need to pass in the specific move, or attributes of said
	# move so that we know what the effects should be. Should it stun/kb? If kb, what's the
	# intensity/specific kb effect?
	
	self._before_hit_computation(hit_char)
	
	# deal values to character
	#self.deal_stun(hit_char)
	self.deal_kb(hit_char)
	var dmg = self.deal_dmg(hit_char)
	
	self._after_hit_computation(hit_char, dmg)


# determines if a hit node is a player
func on_collision_detected(colliding_node) -> void:
	if self.node_is_char(colliding_node) and colliding_node != self.owner_char and (self.hit_chars.get(colliding_node) == null or self.hit_chars.get(colliding_node) == false):
		self.hit_chars[colliding_node] = true
		self.on_hit(colliding_node)


# ------------------- SIGNAL CONNECTION --------------------- #

func area_entered(area: Area3D) -> void:
	on_collision_detected(area)


func body_entered(body: Node3D) -> void:
	on_collision_detected(body)


# ------------------- INIT AND LOOP --------------------- #

# this only runs when the node and ITS CHILDREN and loaded
func _ready() -> void:
	# turn off collisions with default world
	self.set_collision_layer_value(1, false)
	# hitboxes will be on layer 2
	self.set_collision_layer_value(2, true)
	
	# set hitboxes to detect for areas on layer 1, but not layer 2
	self.set_collision_mask_value(1, true)
	self.set_collision_mask_value(2, false)
	
	self.connect("area_entered", area_entered)
	self.connect("body_entered", body_entered)
	

# called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta) -> void:
	pass
