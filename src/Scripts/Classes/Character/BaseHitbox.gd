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

# ------------------------------------------- IMPORTS --------------------------------------------------- #

class_name BaseHitbox
extends Area3D

# ------------------------------------------- PROPERTIES ------------------------------------------------ #

@export var collision_level: int = 1

@export var active : bool = false
var _prev_active : bool = false

# nodes used for the hitbox
@export var collision_shape: CollisionShape3D
@export var mesh_instance: MeshInstance3D	# for hitbox visuals

# the original character object, creator of the hitbox. can be null
@export var owner_char : RollbackCharacterController

# a range of two numbers to indicate what damage rolls the hitbox can have. the second number MUST be greater. integers only
@export var damage_range: Array
var PLAYER_STAMINA_PERCENT_REDUCTION = 0.25

# a dictionary to track hit characters from the hitbox
var hit_chars: Dictionary

# determine how long a character cannot act for when hit, and how long a knockback force is applied
@export var kb_length: float
@export var hitstun_ticks: int
@export var knockback_strength: Vector3

# determines if hitboxes should show or not
@export var debug_on : bool = false

# ------------------------------------------------ METHODS ---------------------------------------------------- #

# overrideable virtual method.
func _before_hit_computation() -> void:
	pass


# overrideable virtual method.
func _after_hit_computation() -> void:
	pass


func deal_stun(hit_char : RollbackCharacterController) -> void:
	hit_char.hitstun_timer.stop()
	hit_char.hitstun_timer.wait_ticks = self.hitstun_ticks
	hit_char.hitstun_timer.start()
	#hit_char.hitstun_ticks += self.hitstun_ticks
	#hit_char.can_move = false
	#var stun_tween = hit_char.get_tree().create_tween()
	#stun_tween.tween_property(hit_char, "can_move", true, hitstun_length)


func deal_kb(hit_char : RollbackCharacterController) -> void:
	var dir_to_enemy = (hit_char.position - owner_char.position).normalized()
	var kb = Vector3(dir_to_enemy.x * knockback_strength.x, knockback_strength.y, dir_to_enemy.z * knockback_strength.z)
	hit_char.knockback = kb


# computes a damage value, then updates an enemy char's hp value
func deal_dmg(hit_char) -> int:
	if not hit_char.invincible:
		var dmg = randi() % (int)(self.damage_range[1] - self.damage_range[0] + 1) + self.damage_range[0]
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
	self._before_hit_computation()
	
	# deal values to character
	if not hit_char.blocking:
		self.deal_kb(hit_char)
		self.deal_stun(hit_char)
		self.deal_dmg(hit_char)
	else:
		hit_char.stamina -= int(hit_char.MAX_STAMINIA_TICKS * 0.25)
		#if hit_char.perfect_block:
		#	pass
			#var temp_stun = self.hitstun_length
			#self.hitstun_length = 1 # is this just always applying the perfect block effect no matter what if the opponent is blocking?
			#self.deal_stun(owner_char)
			#self.hitstun_length = temp_stun


# determines if a hit node is a character. chars have hurtboxes and health
func node_is_char(node) -> bool:
	return node.get_node_or_null("Hurtbox") != null and node.health and node.max_health


func node_is_object(node):
	return node.get_node_or_null("Destruction") != null


func node_is_world(node):
	return node != self.owner_char and !self.node_is_object(node) and !self.node_is_char(node)


# determines if a hit node is a player
func on_collision_detected(colliding_node) -> void:
	if colliding_node == self.owner_char:
		return
	if self.node_is_char(colliding_node) and not self.hit_chars.has(colliding_node.id):
		self.hit_chars[colliding_node.id] = true
		self.on_hit(colliding_node)
	elif (self.node_is_object(colliding_node)):
		# make it so the player can phase through the collding_node
		colliding_node.get_node("Destruction").collision_layer = 0
		colliding_node.get_node("Destruction").destroy()
	elif self.node_is_world(colliding_node):
		pass
	self._after_hit_computation()

# ---------------------------------------------- INIT AND LOOP ------------------------------------------------ #

# this only runs when the node and ITS CHILDREN and loaded
func _ready() -> void:
	# turn off collisions with default world
	# hitboxes will be on layer 3
	self.set_collision_layer_value(3, true)
	
	# set hitboxes to detect for areas on layer 2 and 5
	self.set_collision_mask_value(2, true)
	self.set_collision_mask_value(5, true)


func _network_process(input: Dictionary) -> void:
	if self.active != self._prev_active:
		if self.active:
			self.hit_chars = {}
			self.monitoring = true
			if self.debug_on == true and self.mesh_instance != null:
				self.visible = true
				self.mesh_instance.visible = true
		else:
			self.monitoring = false
			self.hit_chars = {}
			if self.mesh_instance != null:
				self.visible = false
				self.mesh_instance.visible = false
	
	if self.monitoring and self.has_overlapping_bodies():
		for body in self.get_overlapping_bodies():
			on_collision_detected(body)
	
	self._prev_active = self.active


func _save_state() -> Dictionary:
	return {
		active = self.active,
		_prev_active = self._prev_active,
		monitoring = self.monitoring,
		hit_chars = self.hit_chars,
		position = self.position
	}


func _load_state(state: Dictionary) -> void:
	self.active = state["active"]
	self._prev_active = state["_prev_active"]
	self.monitoring = state["monitoring"]
	self.hit_chars = state["hit_chars"]
	self.position = state["position"]


# constructor
func _init(	new_owner_char = null,
			new_damage_range = [5, 5],
			new_kb_length = 0.0, new_hitstun_ticks = 30,
			new_knockback_strength = Vector3.ZERO,
			new_debug_on = false,
			_new_collision_shape = CollisionShape3D.new(),
			_new_mesh_instance = MeshInstance3D.new(),
			new_active = false,
			new_collision_level = 1) -> void:
	self.collision_level = new_collision_level
	self.active = new_active
	self.owner_char = new_owner_char
	
	self.kb_length = new_kb_length
	self.knockback_strength = new_knockback_strength
	self.damage_range = new_damage_range
	self.hitstun_ticks = new_hitstun_ticks
	
	self.hit_chars = {}
	self.name = "Hitbox"
	self.monitoring = false
	
	self.debug_on = new_debug_on
