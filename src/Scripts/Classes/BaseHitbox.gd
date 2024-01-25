# Kyles45678, Chandler Frakes
# This class is the base class for a hitbox in the game.

# HOW TO ADD CUSTOM HITBOXES
	# 1) Add BaseHitbox child node to Hurtbox
	# 2) Attatch a MeshInstance3D as well as a CollisionShape3D node to BaseHitbox node
	# 3) In BaseHitbox node, assign the mesh and collision shape to the corresponding varialbes
		# a) From this point forward, one should be able to mess around with the custom parameters,
		#    position/size of the mesh
	# 4) In the corresponding Move node, assign the BaseHitbox node to this hitbox variable
	# 5) Use the active variable in AnimationPlayer to activate/deactivate the hitbox

# ---------------- IMPORTS ------------------- #

class_name BaseHitbox
extends Area3D

# ---------------- PROPERTIES ----------------- #

@export var active: bool

# nodes used for the hitbox
@export var collision_shape: CollisionShape3D
@export var mesh_instance: MeshInstance3D	# for hitbox visuals

# the original character object, creator of the hitbox. can be null
@export var owner_char : CharacterController

# a range of two numbers to indicate what damage rolls the hitbox can have. the second number MUST be greater. integers only
@export var damage_range: Array

# a dictionary to track hit characters from the hitbox
var hit_chars: Dictionary

# determine how long a character cannot act for when hit, and how long a knockback force is applied
@export var kb_length: float
@export var hitstun_length: float
@export var knockback_strength: Vector3

# determines if hitboxes should show or not
@export var debug_on: bool

# ------------------- METHODS --------------------- #

# constructor
func _init(	owner_char = null,
			damage_range = [5, 5],
			kb_length = 0.0, hitstun_length = 0.5,
			knockback_strength = Vector3.ZERO,
			debug_on = false,
			collision_shape = CollisionShape3D.new(),
			mesh_instance = MeshInstance3D.new(),
			active = false) -> void:
	self.active = active
	self.owner_char = owner_char
	
	self.kb_length = kb_length
	self.knockback_strength = knockback_strength
	self.damage_range = damage_range
	self.hitstun_length = hitstun_length
	
	self.hit_chars = {}
	self.name = "Hitbox"
	self.monitoring = false
	
	self.debug_on = debug_on


# TODO: this function will make use of the owner character node, the enemy character node,
	# and the hitbox node to determine a vector3 for knockback velocity
# 1/22 Note -- Check what is being done in MoveController, is this acceptable? -Chandler
func _calc_kb_vector(enemChar) -> Vector3:
	return Vector3.ZERO


# determines if a hit node is a character. chars have hurtboxes and health
func node_is_char(node) -> bool:
	return node.get_node_or_null("Hurtbox") != null and node.health and node.max_health


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
	hit_char.knockback = knockback_strength
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
	# NOTES FOR FUTURE, we will probs need to pass in the specific move, or attributes of said
	# move so that we know what the effects should be. Should it stun/kb? If kb, what's the
	# intensity/specific kb effect?
	
	self._before_hit_computation(hit_char)
	
	# deal values to character
	self.deal_stun(hit_char)
	self.deal_kb(hit_char)
	var dmg = self.deal_dmg(hit_char)
	
	self._after_hit_computation(hit_char, dmg)


func node_is_object(node):
	return node.get_node_or_null("Destruction") != null
#	return false;


# determines if a hit node is a player
func on_collision_detected(colliding_node) -> void:
#	print(str(colliding_node))
	if self.node_is_char(colliding_node) and colliding_node != self.owner_char and (self.hit_chars.get(colliding_node) == null or self.hit_chars.get(colliding_node) == false):
		self.hit_chars[colliding_node] = true
		self.on_hit(colliding_node)
	elif(self.node_is_object(colliding_node)):
		colliding_node.get_node("Destruction").destroy()

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
	if self.active:
		self.hit_chars = {}
		self.monitoring = true
		if self.debug_on == true and self.mesh_instance != null:
			self.mesh_instance.visible = true
	else:
		self.monitoring = false
		self.hit_chars = {}
		if self.mesh_instance != null:
			self.mesh_instance.visible = false
