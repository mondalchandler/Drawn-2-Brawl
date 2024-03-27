# Chandler Frakes

class_name MoveController
extends Node

# ---------------- PROPERTIES ----------------- #

var owner_char
var anim_tree : AnimationTree
var sprite
var hurtbox : Node
var hb_flipped = false

var move_placeholder = null
var move_input
var timer : Timer
var current_move

# ---------------- FUNCTIONS ---------------- #

func attack(move):
	self.current_move = move
	match move.move_type:
		"MELEE":
			pass
		"GRAB":
			pass
		"GRAPPLE":
			var TETHER: PackedScene = load(move.tether_path)
			if TETHER:
				var tether = TETHER.instantiate()
				# must add the projectile to the map so that it doesn't move w/ character
				self.owner_char.get_parent().get_parent().add_child(tether)
				tether.global_position = self.owner_char.global_position
				tether.owner_char = self.owner_char
				tether.emit()
		"HITSCAN":
			pass
		"PROJECTILE":
			flip_sprite_if_behind()
			for i in range(move.move_data[0]):
				var PROJECTILE: PackedScene = load(move.projectile_path)
				if PROJECTILE:
					var projectile = PROJECTILE.instantiate()
					# must add the projectile to the map so that it doesn't move w/ character
					self.owner_char.get_parent().get_parent().add_child(projectile)
					projectile.global_position = self.owner_char.global_position
					projectile.owner_char = self.owner_char
					await get_tree().create_timer(move.move_data[1][i-1]).timeout
					projectile.emit()


# flips the sprite if a projectile move is player is not facing opponent when shot
func flip_sprite_if_behind():
	# should really only happen when we are targetting
	if owner_char.targetting:
		var dir_to_enemy = (owner_char.z_target.position - owner_char.position).normalized()
		var relative_move_dir = owner_char._get_camera_relative_input() # pass in nothing to get forward vector in return
		var right = (owner_char.transform.basis * Vector3(relative_move_dir.x, 0, relative_move_dir.z)).normalized()
		var angle = right.angle_to(dir_to_enemy)
		if angle < 1.57: # projectile is moving "right"
			if sprite.flip_h == true:
				sprite.flip_h = false
		else: # projectile is moving "left"
			if sprite.flip_h == false:
				sprite.flip_h = true


func flip_hurtbox():
	if (owner_char.sprite.flip_h): # if we are facing left
		owner_char.hurtbox.rotation.y = PI
	else: # else we are facing right
		owner_char.hurtbox.rotation.y = 0


func play_animation():
	owner_char.anim_tree_state_machine.travel(move_input)
	owner_char.can_move = false


func anim_finished(anim_name):
	if anim_name == move_input:
		if move_placeholder:
			move_placeholder.move_reset()
			move_placeholder = null
		clean()
		owner_char._update_core_animations()
		owner_char.can_move = true
		self.owner_char.attacking = false


func clean():
	self.move_input = null
	self.move_placeholder = null


func move_start(move):
	self.owner_char.attacking = true
	self.move_input = move.move_input
	play_animation()
	if move.is_chargable:
		move_placeholder = move
		move_placeholder.move_ended = false
		timer = Timer.new()
		timer.one_shot = true
		self.add_child(timer)
		# if there is custom stopping point in animation for charge move
		# we use move_data[1] to store timestamps, similarly to emitting projectiles
		# removed move_data[0] as does not matter bc we are not iterating through multiple animations
		if move_placeholder.move_data.size() > 0:
			# this should be just short of when the move is active (e.g. if hbx becomes active at 1.8s, have this value be 1.79s)
			# prevents move from instantly activating once charge is complete
			timer.start(move_placeholder.move_data[0]-0.01)
		else:
			# needs to be larger than 0 so that we can properly freeze-frame
			timer.start(0.01)
	else:
		attack(move)


func move_end():
	timer = null
	if move_placeholder and move_placeholder.is_chargable:
		move_placeholder.move_ended = true
		# skip to active frame of move if released
		if move_placeholder.move_data.size() > 0:
			owner_char.anim_tree.set("parameters/" + self.move_input + "/TimeSeek/seek_request", move_placeholder.move_data[0])
		owner_char.anim_tree.set("parameters/" + self.move_input + "/TimeScale/scale", 1)
		attack(move_placeholder)
	pass


func action(event):
	if !(owner_char.anim_tree_state_machine.get_current_node() in owner_char.MOVE_MAP_NAMES):
		if owner_char.is_on_floor() and event.is_pressed():
			if event.is_action_pressed("normal_close"):
				move_start(owner_char.ground_nc)
			if event.is_action_pressed("normal_far"):
				move_start(owner_char.ground_nf)
			if event.is_action_pressed("special_close"):
				move_start(owner_char.ground_sc)
			if event.is_action_pressed("special_far"):
				move_start(owner_char.ground_sf)
		else:
			if event.is_action_pressed("normal_close"):
				move_start(owner_char.air_nc)
			if event.is_action_pressed("normal_far"):
				move_start(owner_char.air_nf)
			if event.is_action_pressed("special_close"):
				move_start(owner_char.air_sc)
			if event.is_action_pressed("special_far"):
				move_start(owner_char.air_sf)

	if event.is_released():
		if owner_char.is_on_floor():
			if event.is_action_released("normal_close") and self.move_input == "ground_nc":
				move_end()
			if event.is_action_released("normal_far") and self.move_input == "ground_nf":
				move_end()
			if event.is_action_released("special_close") and self.move_input == "ground_sc":
				move_end()
			if event.is_action_released("special_far") and self.move_input == "ground_sf":
				move_end()
		else:
			if event.is_action_released("normal_close") and self.move_input == "air_nc":
				move_end()
			if event.is_action_released("normal_far") and self.move_input == "air_nf":
				move_end()
			if event.is_action_released("special_close") and self.move_input == "air_sc":
				move_end()
			if event.is_action_released("special_far") and self.move_input == "air_sf":
				move_end()


func _process(delta):
	if timer:
		if (timer.time_left == 0):
			owner_char.anim_tree.set("parameters/" + self.move_input + "/TimeScale/scale", 0)
	flip_hurtbox()
	if move_placeholder:
		move_placeholder.move_charge_effect(delta)
	pass

# ---------------- INIT ---------------- #

func _init(char, anim_tree, sprite, hurtbox):
	self.owner_char = char
	self.anim_tree = anim_tree
	self.sprite = sprite
	self.hurtbox = hurtbox
	anim_tree.connect("animation_finished", anim_finished)
