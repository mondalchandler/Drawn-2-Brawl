# Chandler Frakes

# SPRITE ANIMATION NOTES
#	When adding animations for different actions, be sure to key the offset with every frame that
#	is added. That way, the _process() function, below, will be able to accurately flip the sprite
#	relative to its origin. This prevents offset/skewed sprite animations when flipped.

extends Sprite3D

# ---------------- PROPERTIES ----------------- #

var current_texture = self.texture

# ---------------- FUNCTIONS ---------------- #

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.current_texture != self.texture:
		self.current_texture = self.texture
		if self.flip_h:
			self.offset.x = -self.offset.x
