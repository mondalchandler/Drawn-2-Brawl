extends Node

@onready var playernode = get_node("Player")
# this is to mock up if you were fighting a player and they scored 3 points by the end of the match
var points_target = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	await run_timer(15)
	var points = playernode.points
	print(points)
	if (points > points_target):
		print("you win")
	elif (points == points_target):
		print("you tied")
	else:
		print("you lose")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func run_timer(period : int):
	print("start")
	await get_tree().create_timer(period).timeout
	print("end")
