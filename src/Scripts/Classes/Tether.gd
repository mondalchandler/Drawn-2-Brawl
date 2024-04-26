# Chandler Frakes

extends BaseHitbox
class_name Tether

# HOW GRAPPLING / TETHERING DATA IS FORMATTED IN move_data:
# [ 0.5 (active monitoring window, can be thought of as legnth of chain),
#   1.5 (legnth of animation so that we can skip to the end if player not detected in window shown above),
#   0.8 ("yoink" frame / point in animation where character reacts to tethering to the opponent),
#   0.4 (time between reaction frames in animation and actual activation of the knockback)]

# ---------------- PROPERTIES ----------------- #

@export var speed: int

var direction
var target_displayed = false
var image = load("res://resources/Images/red_crosshair.png")
var target = Sprite3D.new()
var map
var hooked = false
var active_timer
var full_move_timer
var move_finished = false
var fired_timer = false

# ---------------- FUNCTIONS ---------------- #

func display_target():
	if !self.target_displayed:
		if self.owner_char.targetting:
			var scale = 0.17
			self.target.scale = Vector3(scale, scale, scale)
			self.target.texture = self.image
			self.target.billboard = true
			self.target.transparency = 0.5
			
			self.map = get_parent()
			self.map.add_child(self.target)
			self.map.move_child(self.target, self.map.get_child_count() - 1)
			self.target.global_position = self.owner_char.z_target.global_position
			self.target_displayed = true


# overrideable virtual method.
func _after_hit_computation() -> void:
	queue_free()


func emit():	
	self.direction = get_direction()
	self.active = true


func get_direction():
	if self.owner_char.targetting:
		return self.owner_char.global_position.direction_to(self.owner_char.z_target.global_position)
	else:
		# if not targetting, simply shoot left or right
		if (!self.owner_char.sprite.flip_h):
			return self.owner_char.global_position.direction_to(Vector3(self.owner_char.global_position.x + 1000, 0, self.owner_char.global_position.x + 1000))
		else:
			return self.owner_char.global_position.direction_to(Vector3(self.owner_char.global_position.x - 1000, 0, self.owner_char.global_position.x - 1000))


func on_collision_detected(colliding_node) -> void:
	if self.node_is_char(colliding_node) and colliding_node != self.owner_char and (self.hit_chars.get(colliding_node) == null or self.hit_chars.get(colliding_node) == false):
		self.hit_chars[colliding_node] = true
		self.speed = 0
		self.hooked = true
		self.active = false
		if self.move_finished:
			on_hit(colliding_node)


func finish_move():
	self.owner_char.anim_tree.set("parameters/" + self.owner_char._move_controller.move_input + "/TimeSeek/seek_request", self.owner_char._move_controller.current_move.move_data[2])
	self.owner_char.can_move = false
	await get_tree().create_timer(self.owner_char._move_controller.current_move.move_data[3]).timeout
	self.move_finished = true
	self.active = true

# ------------------- INIT AND LOOP --------------------- #

# this only runs when the node and ITS CHILDREN have loaded
func _ready() -> void:
	# turn off collisions with default world
	# hitboxes will be on layer 3
	self.set_collision_layer_value(3, true)
	
	# set hitboxes to detect for areas on layer 2 and 5
	self.set_collision_mask_value(2, true)
	self.set_collision_mask_value(5, true)
	
	self.connect("area_entered", area_entered)
	self.connect("body_entered", body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# start the monitoring window to grab opponent
	if !fired_timer:
		active_timer = Timer.new()
		active_timer.one_shot = true
		self.add_child(active_timer)
		# active window
		active_timer.start(self.owner_char._move_controller.current_move.move_data[0])
		self.fired_timer = true
	if self.hooked:
		self.global_position = self.owner_char.z_target.global_position
	else:
		self.owner_char.can_move = true
	if active_timer:
		if active_timer.time_left > 0:
			if hooked:
				active_timer = null
				finish_move()
		else:
			# cancel/skip to end of animation and queue_free()
			self.owner_char.anim_tree.set("parameters/" + self.owner_char._move_controller.move_input + "/TimeSeek/seek_request", self.owner_char._move_controller.current_move.move_data[1])
			_after_hit_computation()
	if self.active:
		if self.target_displayed:
			self.map.remove_child(self.target)
		self.global_position += self.speed * self.direction * delta
		self.hit_chars = {}
		self.monitoring = true
		if owner_char.debug_on == true and self.mesh_instance != null:
			self.mesh_instance.visible = true
	else:
#		display_target() <- not doing anything w this rn because we aren't waiting to emit the grapple, also crosshair appears when we apply kb
		self.global_position = self.owner_char.global_position
		self.monitoring = false
		self.hit_chars = {}
		if self.mesh_instance != null:
			self.mesh_instance.visible = false


func _init(speed = 0):
	super()
	self.speed = speed
