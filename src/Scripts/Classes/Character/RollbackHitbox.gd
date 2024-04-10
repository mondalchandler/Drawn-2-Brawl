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

class_name RollbackHitbox
extends Area3D

# ---------------- PROPERTIES ----------------- #

@export var collision_level: int = 1
@export var active: bool

# nodes used for the hitbox
@export var collision_shape: CollisionShape3D
@export var mesh_instance: MeshInstance3D	# for hitbox visuals

# the original character object, creator of the hitbox. can be null
@export var owner_char : RollbackCharacterController

# a range of two numbers to indicate what damage rolls the hitbox can have. the second number MUST be greater. integers only
@export var damage_range: Array  = [5, 5]
var PLAYER_STAMINA_PERCENT_REDUCTION = 0.25

# a dictionary to track hit characters from the hitbox
var hit_chars: Dictionary = {}

# determine how long a character cannot act for when hit, and how long a knockback force is applied
@export var kb_length: float = 0.0
@export var hitstun_length: float = 0.5
@export var knockback_strength: Vector3 = Vector3.ZERO

# determines if hitboxes should show or not
@export var debug_on: bool

@onready var hb_timer = $HitboxDebounce

var kb_x
var kb_y
var kb_z

var dealt_kb = false
var dealt_stun = false

# ------------------- METHODS --------------------- #


# overrideable virtual method.
func _before_hit_computation() -> void:
	pass


# overrideable virtual method.
func _after_hit_computation() -> void:
	self.dealt_kb = false
	self.dealt_stun = false
	self.active = false


func deal_stun(hit_char) -> void:
	if !dealt_stun:
		hit_char.can_move = false
		var stun_tween = hit_char.get_tree().create_tween()
		stun_tween.tween_property(hit_char, "can_move", true, hitstun_length)
		dealt_stun = true


# Custom easing function (linear interpolation)
func lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t


# Custom tweening function
func custom_tween(node: Node, property: String, target_value: Variant, duration: float):
	var start_value = node.get(property)
	var elapsed_time = 0.0

	while elapsed_time < duration:
		var t = elapsed_time / duration
		var interpolated_value = lerp(start_value, target_value, t)
		node.set(property, interpolated_value)
		await get_tree().create_timer(0.016667).timeout  # Wait for one frame
		elapsed_time += 0.016667


func deal_kb(hit_char) -> void:
	if !dealt_kb:
		hb_timer.start()
		var dir_to_enemy = (hit_char.position - owner_char.position).normalized()
		#hit_char.kb_x = dir_to_enemy.x * knockback_strength.x
		#hit_char.kb_y = knockback_strength.y
		#hit_char.kb_z = dir_to_enemy.z * knockback_strength.z
		kb_x = dir_to_enemy.x * knockback_strength.x
		kb_y = knockback_strength.y
		kb_z = dir_to_enemy.z * knockback_strength.z
		
		#hit_char.knockback = Vector3(0.1, 0.1, 0.1) kb_x, kb_y, kb_z 1, 1, 1
		hit_char.velocity += Vector3(kb_x, kb_y, kb_z)
		
		#print("kb in RollbackHitbox.gd:")
		#print(hit_char.knockback)
		dealt_kb = true
		#custom_tween(hit_char, "knockback", Vector3.ZERO, kb_length)
		#var knockback_tween = hit_char.get_tree().create_tween()
		#knockback_tween.tween_property(hit_char, "knockback", Vector3.ZERO, kb_length)


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
	self.deal_kb(hit_char)
	# deal values to character
	#if not hit_char.blocking:
		##self.deal_stun(hit_char)
		#self.deal_kb(hit_char)
		##self.deal_dmg(hit_char)
	#else:
		#hit_char.stamina -= hit_char.STAMINA_AMOUNT * PLAYER_STAMINA_PERCENT_REDUCTION
		#if hit_char.perfect_block:
			#var temp_stun = self.hitstun_length
			#self.hitstun_length = 1 # is this just always applying the perfect block effect no matter what if the opponent is blocking?
			#self.deal_stun(owner_char)
			#self.hitstun_length = temp_stun
	
	self._after_hit_computation()


# determines if a hit node is a character. chars have hurtboxes and health
func node_is_char(node) -> bool:
	return node.get_node_or_null("Hurtbox") != null and node.health and node.max_health


func node_is_object(node):
	return node.get_node_or_null("Destruction") != null


func node_is_world(node):
	return node != self.owner_char and !self.node_is_object(node) and !self.node_is_char(node)


# determines if a hit node is a player
func on_collision_detected(colliding_node) -> void:
	if self.node_is_char(colliding_node) and colliding_node != self.owner_char and (self.hit_chars.get(colliding_node) == null or self.hit_chars.get(colliding_node) == false):
		self.hit_chars[colliding_node] = true
		self.on_hit(colliding_node)
	elif (self.node_is_object(colliding_node)):
		# make it so the player can phase through the collding_node
		colliding_node.get_node("Destruction").collision_layer = 0
		colliding_node.get_node("Destruction").destroy()
		self._after_hit_computation()
	elif self.node_is_world(colliding_node):
		self._after_hit_computation()

# ------------------- SIGNAL CONNECTION --------------------- #

func area_entered(area: Area3D) -> void:
	on_collision_detected(area)


func body_entered(body: Node3D) -> void:
	on_collision_detected(body)

# ------------------- INIT AND LOOP --------------------- #

# this only runs when the node and ITS CHILDREN and loaded
func _ready() -> void:
	# turn off collisions with default world
	# hitboxes will be on layer 3
	self.set_collision_layer_value(3, true)
	
	# set hitboxes to detect for areas on layer 2 and 5
	self.set_collision_mask_value(2, true)
	self.set_collision_mask_value(5, true)
	
	self.connect("area_entered", area_entered)
	self.connect("body_entered", body_entered)


# called every frame. 'delta' is the elapsed time since the previous frame
func _network_process(_input: Dictionary) -> void:
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


func _save_state() -> Dictionary:
	return {
		active = self.active,
		monitoring = self.monitoring,
		hit_chars = self.hit_chars,
		kb_x = self.kb_x,
		kb_y = self.kb_y,
		kb_z = self.kb_z,
		dealt_kb = self.dealt_kb,
		dealt_stun = self.dealt_stun
	}


func _load_state(state: Dictionary) -> void:
	self.active = state["active"]
	self.monitoring = state["monitoring"]
	self.hit_chars = state["hit_chars"]
	self.kb_x = state["kb_x"]
	self.kb_y = state["kb_y"]
	self.kb_z = state["kb_z"]
	self.dealt_kb = state["dealt_kb"]
	self.dealt_stun = state["dealt_stun"]

