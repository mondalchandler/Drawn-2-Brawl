extends Control

@onready var server_list := $"Server Container/Server List"
@onready var room_debug_output := $"Room Debug/Room Debug Output"
@onready var filter_input := $"Filter Container/Filter Input"
@onready var passcode_box := $"Passcode Container"
@onready var passcode_label := $"Passcode Container/Passcode Header"
@onready var passcode_input := $"Passcode Container/Passcode Input"
@onready var passcode_success := $"Passcode Container/Join Success"

var len := 0
var password := ""

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


func _on_run_filter_pressed():
	for row in server_list.get_children():
		var label = row.get_child(0)
		if len(filter_input.text) == 0 or filter_input.text in label.text:
			row.show()
		else:
			row.hide()

func _on_join_pressed():
	if password == passcode_input.text:
		passcode_success.text = "Success"
	else:
		passcode_success.text = "Failure"

func generate_row() -> Control:
	var num = 1000 + randi() % 9000
	
	var label = Label.new()
	label.size = Vector2(400, 30)
	label.text = "Room " + str(num)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var join_room = Button.new()
	join_room.size = Vector2(50, 30)
	join_room.text = "Join"
	join_room.pressed.connect(Callable(show_passcode).bind(num, str(num)))
	
	var row = HBoxContainer.new()
	row.size = Vector2(400, 30)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(label)
	row.add_child(join_room)
	return row

func show_passcode(num: int, password_: String):
	passcode_box.show()
	passcode_label.text = "Pass for Room " + str(num)
	password = password_





