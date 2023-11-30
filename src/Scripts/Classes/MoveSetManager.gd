# Chandler Frakes

extends Node

# ---------------- CONSTANTS ---------------- #

const MOVE_TYPES = ["MELEE", "GRAB", "GRAPPLE", "HITSCAN", "PROJECTILE"]

# HOW MOVE DATA IS STRUCTURED FOR EACH TYPE
# MELEE (i.e. Regular Hitbox):		[offset, dmg, hitstun, kb_length, kb_stg, hitbox_size]
# HITSCAN:							[dmg, hitstun, kb_stg]

# ---------------- GLOBALS ---------------- #

var ranger_moves = {
	"GNC":
		[
			# move type
			"Pistol Whip",
			# move classification
			MOVE_TYPES[0],
			# move data (see above for format), here we are passing a hitbox for a simple melee attack
			# we might pass different data for different types of moves
			[Transform3D(Basis.IDENTITY, Vector3(.5, 0, .5)), [10, 10], 0.1, 0.1, Vector3(4, 4, 4), Vector3(1.2, .8, 1)]
		],
	"GNF":
		[
			"One Shot",
			MOVE_TYPES[3],
			[[10, 10], 0.2, Vector3(4, 4, 4)]
		],
	"GSC":
		[
			"Axe Uppercut",
			# using "GRAB" only to test animations
			MOVE_TYPES[1]
		],
	"GSF":
		[
			"Three Shot Burst",
			MOVE_TYPES[1]
		],
	"ANC":
		[
			"Air Axe",
			MOVE_TYPES[1]
		],
	"ANF":
		[
			"Throwing Knife",
			MOVE_TYPES[1]
		],
	"ASC":
		[
			"Shotgun Explosion",
			MOVE_TYPES[1]
		],
	"ASF":
		[
			"Lasso Pull",
			MOVE_TYPES[1]
		]
}
