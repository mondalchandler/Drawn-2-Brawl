# Alex Ottelien, Kyle Senebouttarath

# ------------------ IMPORTS ------------------- #

class_name CustomButton
extends Polygon2D

# ------------------ NODES ------------------- #

@onready var main_scene = get_tree().root.get_node("main_scene")
@onready var music_node: Node = main_scene.get_node("MusicNode")

#this method exists as a just in case, where I can't change the position any other way.
@onready var x = self.position.x
@onready var y = self.position.y
@onready var default_res_x: float = 1920
@onready var default_res_y: float = 1080

@onready var tempo_spring: Spring = Spring.new(0)

var default_scale

# ------------------ HELPER FUNCTIONS ------------------- #


func position_method():
	var size = get_tree().root.size
	var scale_x = size.x/default_res_x
	var scale_y = size.y/default_res_y
	self.position.x = x*scale_x
	self.position.y = y*scale_y
	self.scale.x = scale_x
	self.scale.y = scale_y


func run_task():
	pass


func _on_pulse(beat_count):
	tempo_spring.impulse(1.25 + (1 if beat_count % 2 == 0 else 0))
	pass
	#
	#print(tempo_spring.speed, tempo_spring.damper)
	#print()


# ------------------ MAIN FUNCTIONS ------------------- #


# Called when the node enters the scene tree for the first time.
func _ready():
	position_method()
	tempo_spring.set("speed", 20.5)
	tempo_spring.set("damper", 0.44)
	music_node.connect("on_music_pulse", _on_pulse)
	default_scale = self.scale


func _process(delta):
	#print(tempo_spring.get("position"), Time.get_unix_time_from_system())
	self.scale.y = default_scale.y + tempo_spring.get("position")
	self.scale.x = default_scale.x + tempo_spring.get("position")
