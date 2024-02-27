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

# ---------------- FUNCTIONS ---------------- #

func attack(move):
	flip_hurtbox()
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
			flip_sprite_if_behind()
			for i in range(move.move_data[0]):
				var PROJECTILE: PackedScene = load(move.projectile_path)
				if PROJECTILE:
					var projectile = PROJECTILE.instantiate()
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
		owner_char.anim_tree.set("parameters/" + self.move_input + "/TimeScale/scale", 0)
	else:
		attack(move)


func move_end():
	if move_placeholder and move_placeholder.is_chargable:
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
	if move_placeholder:
		move_placeholder.move_charge_effect(delta)
	pass

# ---------------- INIT ---------------- #

func _init(character, new_anim_tree, new_sprite, new_hurtbox):
	self.owner_char = character
	self.anim_tree = new_anim_tree
	self.sprite = new_sprite
	self.hurtbox = new_hurtbox
	anim_tree.connect("animation_finished", anim_finished)
