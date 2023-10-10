# Kyle Senebouttarath

# ---------------- EXTENDS ---------------- #

extends Node3D

# ---------------- INSTANCES ---------------- #

@onready var lead_layer = $LeadLayer

# ---------------- SIGNALS ---------------- #

signal enable_pause_music
signal disable_pause_music

# ---------------- GLOBALS ---------------- #

var paused = false
var volumeTween

# ---------------- FUNCTIONS ---------------- #

func tween_to_volume(goal_vol):
	if volumeTween:
		volumeTween.kill()
		
	volumeTween = self.create_tween()	
	volumeTween.tween_property(self, "metadata/CurrentVolume", goal_vol, 0.5)
	volumeTween.play()
	
	
func on_pause():
	paused = true
	tween_to_volume(self.get_meta("PauseVolume"))
	
	
func on_unpause():
	paused = false	
	tween_to_volume(self.get_meta("DefaultVolume"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for layer in self.get_children():
		layer.volume_db = self.get_meta("CurrentVolume")
	
	if paused:
		lead_layer.volume_db = -80
		
# ---------------- INIT ---------------- #

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# just in case
	self.set_meta("DefaultVolume", -23)
	self.set_meta("CurrentVolume", -23)
	self.set_meta("PauseVolume", -35)
	
	enable_pause_music.connect(on_pause)
	disable_pause_music.connect(on_unpause)

