extends CustomButton

@export var Character: PackedScene
@onready var parent: Node = get_node("../../")

func run_task():
	parent._load_player(Character)
