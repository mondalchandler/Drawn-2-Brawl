# Chandler Frakes

class_name MoveController
extends Node

# ---------------- PROPERTIES ----------------- #

var owner_char
var anim_player
var sprite
var hurtbox : Node

var hitbox
var move_name
var debug_on = true

# ---------------- FUNCTIONS ---------------- #

func attack(move):
	self.move_name = move.move_name
	
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
	if anim_player.is_playing():
		anim_player.stop()
	anim_player.play(move_name)


func anim_finished(anim_name):
	if hitbox:
		hitbox._deactivate()
		pass
	clean()


func clean():
	self.hitbox = null
	self.move_name = null

# ---------------- INIT ---------------- #

func _init(char, anim_player, sprite, hurtbox):
	self.owner_char = char
	self.anim_player = anim_player
	self.sprite = sprite
	self.hurtbox = hurtbox
