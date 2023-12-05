# Chandler Frakes

class_name MoveController
extends Node

# ---------------- PROPERTIES ----------------- #

var owner_char
var anim_tree : AnimationTree
var sprite
var hurtbox : Node

var hitbox
var move_name
var debug_on = true

# ---------------- FUNCTIONS ---------------- #

func attack(move):
	
	if !(owner_char.anim_tree_state_machine.get_current_node() in owner_char.MOVE_MAP_NAMES):
		self.move_name = move.move_name
		
		# do the specific action
		match move.move_type:
			"normal_close":
				hitbox = BoxHitbox.new(owner_char, move.move_data[0], move.move_data[1], move.move_data[2], move.move_data[3], move.move_data[4], move.move_data[5], debug_on)
				hurtbox.add_child(hitbox.mesh_instance)
				hitbox._activate()
				
				if (sprite.flip_h):
					hurtbox.rotation.y = PI 
				else:
					hurtbox.rotation.y = 0
			"normal_far":
				pass
			"special_close":
				pass
			"special_far":
				pass
			
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
			
		play_animation(move.move_type)


func play_animation(move_type: String):
	owner_char.anim_tree_state_machine.travel(move_type)
#	if anim_player.is_playing():
#		anim_player.stop()
#	anim_player.play(move_name)
	


func anim_finished(anim_name):
	if anim_name == move_name:
		if hitbox:
			hitbox._deactivate()
			pass
		clean()
		owner_char._update_core_animations()



func clean():
	self.hitbox = null
	self.move_name = null

# ---------------- INIT ---------------- #

func _init(char, anim_tree, sprite, hurtbox):
	self.owner_char = char
	self.anim_tree = anim_tree
	self.sprite = sprite
	self.hurtbox = hurtbox
	anim_tree.connect("animation_finished", anim_finished)
