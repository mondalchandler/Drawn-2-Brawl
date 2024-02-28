extends Control

@onready var server_list := $"Server Container/Server List"
@onready var room_debug_output := $"Room Debug/Room Debug Output"
var len := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_add_room_pressed():
	server_list.add_child(generate_row())
	room_debug_output.text = "Added room (len " + str(server_list.get_child_count()) + ")"


func _on_remove_room_pressed():
	len = server_list.get_child_count()
	if len > 0:
		server_list.remove_child(server_list.get_child(len - 1))
	room_debug_output.text = "Removed room (len " + str(server_list.get_child_count()) + ")"


func generate_row() -> Control:
	var label = Label.new()
	label.size = Vector2(400, 30)
	label.text = "Room " + str(1000 + randi() % 9000)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var join_room = Button.new()
	join_room.size = Vector2(50, 30)
	join_room.text = "Join"
	
	var row = HBoxContainer.new()
	row.size = Vector2(400, 30)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(label)
	row.add_child(join_room)
	return row
