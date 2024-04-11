extends BaseHitbox


func on_collision_detected(colliding_node) -> void:
	if colliding_node.get_collision_layer_value(2):
		deal_dmg(colliding_node)
	if colliding_node.get_collision_layer_value(1) or colliding_node.get_collision_layer_value(2):
		self.get_parent().get_node("Destruction").destroy()


func deal_dmg(hit_char) -> int:
	if not hit_char.invincible:
		var dmg = 20
		var new_hp = hit_char.health - dmg
		if new_hp < 0:
			new_hp = 0
		hit_char.health = new_hp
		return dmg
	else:
		return 0
