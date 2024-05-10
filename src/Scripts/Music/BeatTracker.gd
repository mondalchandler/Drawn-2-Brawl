# Kyle Senebouttarath

# ----------------------- IMPORTS ---------------------------#

class_name BeatTracker
extends Node

# ----------------------- PROPERTIES ---------------------------#

@export var MUSIC_FOLDER_NAME = "MenuMusic"
@export var BPM: float = 140.0
@export var DEFAULT_VOLUME: float = 0.0
@export var MS_OFFSET : int = 0
@export var BEAT_FREQUENCY: int  = 1

# ----------------------- GLOBALS ---------------------------#

@onready var included_layers = {
	"VocalLayer": $VocalLayer,
	"LeadLayer": $LeadLayer,
	"MidLayer": $MidLayer,
	"BassLayer": $BassLayer,
	"DrumLayer": $DrumLayer
}

var beat_count: int = 0
var playing: bool = false

var time_begin

signal beat_audio

# ----------------------- FUNCTIONS ---------------------------#


func real_bpm():
	return BPM / BEAT_FREQUENCY


func play():
	time_begin = Time.get_ticks_usec()
	time_begin += MS_OFFSET * 1000
	time_begin += (AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()) * 1000000
	beat_count = 0
	for layer in self.get_children():
		layer.play()


func stop():
	for layer in self.get_children():
		layer.stop()
	beat_count = 0


func set_volume(volume: float) -> void:
	for layer in self.get_children():
		layer.volume_db = volume


func reset_volume() -> void:
	for layer in self.get_children():
		layer.volume_db = DEFAULT_VOLUME


func set_layer_volume(layer_prefix: String, volume: float) -> void:
	if self.find_child(layer_prefix + "Layer"):
		self.find_child(layer_prefix + "Layer").volume_db = volume


func begin_ms():
	return time_begin / 1000.0


func cur_ms():
	return Time.get_ticks_msec() - begin_ms()


func load_mp3(path):
	if FileAccess.file_exists(path): 
		var file = FileAccess.open(path, FileAccess.READ)
		var sound = AudioStreamMP3.new()
		sound.data = file.get_buffer(file.get_length())
		return sound


# ----------------------- MAIN ---------------------------#


func _ready():
	for layer_name in included_layers.keys():
		var path = "res://resources/Music/" + MUSIC_FOLDER_NAME + "/" + layer_name + ".mp3"
		var audio_stream = load_mp3(path)
		if audio_stream:
			audio_stream.loop = true
			audio_stream.bpm = real_bpm()
			included_layers[layer_name].stream = audio_stream
			included_layers[layer_name].volume_db = DEFAULT_VOLUME


func _process(_delta):
	var ms_between_beats = 60000.0 / real_bpm()
	var audio_delay = (AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()) * 1000
	
	if cur_ms() >= beat_count * ms_between_beats - audio_delay:
		beat_count += 1
		emit_signal("beat_audio", beat_count)#, (beat_count - 1) * ms_between_beats - audio_delay + begin_ms())
	

