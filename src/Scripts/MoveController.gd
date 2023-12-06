# Chandler Frakes

class_name MoveController
extends Node

# ---------------- PROPERTIES ----------------- #

var owner_char
var anim_tree : AnimationTree
var sprite
var hurtbox : Node

var hitbox
var move_input
var debug_on = true

# ---------------- FUNCTIONS ---------------- #

func attack(move):
	self.move_input = move.move_input
	
	if !(owner_char.anim_tree_state_machine.get_current_node() in owner_char.MOVE_MAP_NAMES):		
		# do the specific action
		match move.move_type:
			"MELEE":
				hitbox = BoxHitbox.new(owner_char, move.move_data[0], move.move_data[1], move.move_data[2], move.move_data[3], move.move_data[4], move.move_data[5], debug_on)
				hurtbox.add_child(hitbox.mesh_instance)
				hitbox._activate()
				
				if (sprite.flip_h):
					hurtbox.rotation.y = PI 
				else:
					hurtbox.rotation.y = 0
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


func anim_finished(anim_name):
	if anim_name == move_input:
		if hitbox:
			hitbox._deactivate()
			pass
		clean()
		owner_char._update_core_animations()


func clean():
	self.hitbox = null
	self.move_input = null

# ---------------- INIT ---------------- #

func _init(char, anim_tree, sprite, hurtbox):
	self.owner_char = char
	self.anim_tree = anim_tree
	self.sprite = sprite
	self.hurtbox = hurtbox
	anim_tree.connect("animation_finished", anim_finished)
