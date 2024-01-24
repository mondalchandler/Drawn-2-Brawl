# Chandler Frakes

class_name MoveController
extends Node

# ---------------- PROPERTIES ----------------- #

var owner_char
var anim_tree : AnimationTree
var sprite
var hurtbox : Node
var hb_flipped = false

var move_input

# ---------------- FUNCTIONS ---------------- #

func attack(move):
	if !(owner_char.anim_tree_state_machine.get_current_node() in owner_char.MOVE_MAP_NAMES):	
		self.move_input = move.move_input
		
		# do the specific action
		match move.move_type:
			"MELEE":
				if (sprite.flip_h):		# if we are facing left
					hurtbox.rotation.y = PI
					if (move.hitbox.knockback_strength.x > 0 && move.hitbox.knockback_strength.z > 0):	# if the move magnitude is rightward, make it face left
						move.hitbox.knockback_strength *= Vector3(-1, 1, -1)
				else:					# else we are facing right
					hurtbox.rotation.y = 0
					if (move.hitbox.knockback_strength.x < 0 && move.hitbox.knockback_strength.z < 0):	# if the move magnitude is leftward, make it face right
						move.hitbox.knockback_strength *= Vector3(-1, 1, -1)
			"GRAB":
				pass
			"GRAPPLE":
				pass
			"HITSCAN":
				# we will most likely have a Hitscan class
				# params to pass in would be something like owner_char and target_char
				pass
			"PROJECTILE":
				pass
			
		play_animation()


func play_animation():
	owner_char.anim_tree_state_machine.travel(move_input)
	owner_char.can_move = false


func anim_finished(anim_name):
	if anim_name == move_input:
		clean()
		owner_char._update_core_animations()
		owner_char.can_move = true


func clean():
	self.move_input = null

# ---------------- INIT ---------------- #

func _init(char, anim_tree, sprite, hurtbox):
	self.owner_char = char
	self.anim_tree = anim_tree
	self.sprite = sprite
	self.hurtbox = hurtbox
	anim_tree.connect("animation_finished", anim_finished)
