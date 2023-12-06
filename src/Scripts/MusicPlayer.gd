# Kyle Senebouttarath

# ---------------- EXTENDS ---------------- #

extends Node

# ---------------- CONSTANTS ---------------- #

const DEFAULT_VOLUME: float = 0.0
const PAUSE_VOLUME: float = DEFAULT_VOLUME - 25.0

# ---------------- PROPERTIES ---------------- #

var in_game_pause: bool = false
var _volumeTween
var current_song_scene = null
@export var volume: float = 0.0

# ---------------- SIGNALS ---------------- #

signal enable_pause_music
signal disable_pause_music

signal on_music_pulse

# ---------------- FUNCTIONS ---------------- #


func stop():
	if current_song_scene:
		current_song_scene.stop()


func play():
	if current_song_scene:
		current_song_scene.play()


func on_beat(beat_num):
	on_music_pulse.emit(beat_num)


func load_song(song_scene):
	# clear everything in the main scene
	for i in self.get_children():
		i.queue_free()
			
	if current_song_scene:
		current_song_scene = null
	
	current_song_scene = load(song_scene).instantiate()
	current_song_scene.connect("beat_audio", on_beat)
	
	# load the new scene
	self.add_child(current_song_scene)


func tween_to_volume(goal_vol):
	if _volumeTween:
		_volumeTween.kill()
		
	_volumeTween = self.create_tween()	
	_volumeTween.tween_property(self, volume, goal_vol, 0.5)
	_volumeTween.play()


func on_game_pause():
	in_game_pause = true
	tween_to_volume(PAUSE_VOLUME)


func on_game_unpause():
	in_game_pause = false
	tween_to_volume(current_song_scene.volume if current_song_scene != null else DEFAULT_VOLUME)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_song_scene:
		current_song_scene.set_volume(volume)
		
		if in_game_pause:
			current_song_scene.set_layer_volume("Lead", -80)


# ---------------- INIT ---------------- #


# Called when the node enters the scene tree for the first time.
func _ready():
	load_song("res://resources/Music/MenuMusic/MenuMusic.tscn")
	play()

