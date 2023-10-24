# Kyles45678
# This class is the base class for a hitbox in the game. 

# ---------------- IMPORTS ------------------- #

extends Node
class_name BaseHitbox

# ---------------- PROPERTIES ----------------- #

var ownerChar

var active: bool

var hit_chars: Dictionary
var damage_range: Array
var hitstun_length: float

var hitbox: MeshInstance3D
var origin_offset: Transform3D

var kb_length: float

# ---------------- METHODS --------------------- #

func _init() -> void:
	pass
	


func _activate() -> void:
	hit_chars = {}
	active = true


func _deactivate() -> void:
	active = false
	hit_chars = {}


func _calc_kb_vector(originChar, enemChar, hitboxNode) -> Vector3:
	pass


func _is_colliding(enemChar) -> bool:
	var isColliding = false
	if enemChar and hitbox and enemChar.get_node_or_null("Hurtbox") and 


func _on_hit(originChar, hitChar, d):
	



# called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta):
	pass
