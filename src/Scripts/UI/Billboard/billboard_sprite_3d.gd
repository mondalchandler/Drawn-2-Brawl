@tool

extends Sprite3D

@export var text: String = "OnlyTwentyCharacters"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$BillboardViewport.size = $BillboardViewport/Label.get_rect().size
	$BillboardViewport/Label.text = self.text
