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
		
		flip_hurtbox()
		
		# do the specific action
		match move.move_type:
			"MELEE":
				pass
			"GRAB":
				pass
			"GRAPPLE":
				pass
			"HITSCAN":
				pass
			"PROJECTILE":
				pass
			
		play_animation()


func flip_hurtbox():
	if (owner_char.sprite.flip_h):		# if we are facing left
		owner_char.hurtbox.rotation.y = PI
	else:					# else we are facing right
		owner_char.hurtbox.rotation.y = 0


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
