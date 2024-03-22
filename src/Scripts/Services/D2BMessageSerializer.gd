#Kyle Senebouttarath

extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

# -------------------- CONSTANTS --------------------- #

# player number + input header + WASD vector + move input integer
const PLAYER_INPUT_SIZE : int = 1 + 1 + 8 + 1
const DEBUG_OUTPUT : bool = false

# -------------------- OPTIMIZED VERSION: SERIALIZING DATA --------------------- #

# this is used to map these individual unique paths to integer values
const input_path_mapping := {
	'/root/main_scene/Players/Player1': 1,
	'/root/main_scene/Players/Player2': 2,
}

# this creates a reverse of our input_path_mapping dictionary used to decode our serialized data
var input_path_mapping_reverse = {}
func _init() -> void:
	for key in input_path_mapping:
		input_path_mapping_reverse[input_path_mapping[key]] = key


# some bit flags used to indicate if our code has certain elements within the network message 
	# if we need more flags, we should go up in increments (0x01, 0x02, 0x04, 0x08, 0x10, etc...)
	# the purpose of doing it this is that it allows us to send multiple input states in a single byte for the header
	# this is VERY SIMILAR to how it is done with our robot in Real-Time Systems
enum HeaderFlags {
	HAS_INPUT_VECTOR = 		0x01,	# (Binary: 00000001)
	JUMP_INPUT = 			0x02,	# (Binary: 00000010)
	BLOCK_HOLD_INPUT = 		0x04,	# (Binary: 00000100)
	ROLL_INPUT = 			0x08,	# (Binary: 00001000)
	TARGET_INPUT = 			0x10,	# (Binary: 00010000)
	TARGET_CHANGE_INPUT = 	0x20,	# (Binary: 00100000)
	HOLDING_MOVE_INPUT = 	0x40	# (Binary: 01000000)
}

enum MoveFlags {
	NORMAL_CLOSE = 	0x01,
	NORMAL_FAR = 	0x02,
	SPECIAL_CLOSE = 0x04,
	SPECIAL_FAR = 	0x08
}

func per_player_serialize_input(buffer, player_input) -> void:
	var header := 0
	
	# if they have an input vector
	if player_input.has("input_vector"):
		# bitwise OR assignment being performed on the header value (0) and the HAS_INPUT_VECTOR enum (0x01)
		# this value is then assigned into the header variable (aka we flipped it to be 0x01 now)
		# the |= can be used to essentially "append" more header data into the the header
		header |= HeaderFlags.HAS_INPUT_VECTOR
	# if they have a jump input
	if player_input.get("pressed_jump", false):
		header |= HeaderFlags.JUMP_INPUT
	
	# if they have a blocking input thats being held
	if player_input.has("holding_block"):
		header |= HeaderFlags.BLOCK_HOLD_INPUT
	# if they have a rolling input that was pressed
	if player_input.get("roll", false):
		header |= HeaderFlags.ROLL_INPUT
	
	# if they have a target input
	if player_input.get("pressed_target", false):
		header |= HeaderFlags.TARGET_INPUT
	# if they have a target changing input
	if player_input.get("pressed_change_target", false):
		header |= HeaderFlags.TARGET_CHANGE_INPUT
	
	# if they have move input
	if player_input.has("normal_close") or player_input.has("normal_far") or player_input.has("special_close") or player_input.has("special_far"):
		header |= HeaderFlags.HOLDING_MOVE_INPUT
	
	# now we write a single byte for our header to indicate that our input_vector exists or not
	buffer.put_u8(header)
	
	# now we write the data if it exists
	if player_input.has("input_vector"):
		var input_vector: Vector2 = player_input["input_vector"]
		
		# this writes 4 bytes for the X value and 4 bytes for the Y value
		buffer.put_float(input_vector.x)
		buffer.put_float(input_vector.y)
	
	# we write an integer to determine what we're holding a move down for
	if player_input.has("normal_close") or player_input.has("normal_far") or player_input.has("special_close") or player_input.has("special_far"):
		var move_header := 0
		if player_input.has("normal_close"):
			move_header |= MoveFlags.NORMAL_CLOSE
		if player_input.has("normal_far"):
			move_header |= MoveFlags.NORMAL_FAR
		if player_input.has("special_close"):
			move_header |= MoveFlags.SPECIAL_CLOSE
		if player_input.has("special_far"):
			move_header |= MoveFlags.SPECIAL_FAR
		buffer.put_u8(move_header)


# @Override 
# this code will convert input data into bytes. By default, it uses the "var_to_bytes()" method,
# but we can customize this for our purposes to save on bytes and make messages smaller
# this improved code goes down from a worse case scenario of 104 bytes to 15 bytes!
	# in best case (no input), this would be 7 bytes
func serialize_input(all_input: Dictionary) -> PackedByteArray:
	
	if DEBUG_OUTPUT:
		var bytes = var_to_bytes(all_input)
		print("initial game input dictionary size: %s" % bytes.size())
	
	# create a new byte buffer and track how many players are inputting
	var buffer := StreamPeerBuffer.new()
	# we subtract 1 because we don't want to count the "$" entry 
	var num_players_inputting = all_input.size() - 1
	
	# allocating a max value that we think will be bigger than what we put into this
	var buffer_size = 4 + 1 + num_players_inputting * PLAYER_INPUT_SIZE
	if DEBUG_OUTPUT:
		print("guess-estimate buffer size: ", buffer_size)
	buffer.resize(buffer_size)
	
	# ---------- BUFFER WRITING --------- #
	
	# this puts the input hash into the buffer in the size of a 32 bit unsigned integer (32 bits = 4 bytes)
	# in this case, the first four bytes of our buffer is an input hash used to compare real input and predicted input for rollbacks
	# this is why we did "4" in .resize
	buffer.put_u32(all_input['$'])
	
	# we now allocate 1 single byte to indicate how much input we're putting into this buffer
		# this solution puts the size of all possible input sources based on the all_input size
		# the all_input variable stores multiple sub-dictionarys of input per player
	# this is why we did "+ 1" in .resize
	buffer.put_u8(num_players_inputting)
	
	# we now iterate through the rest of the values in the dictionary
		# there should only be one other key-value pair (the path to the player), but since we don't know the key
		# of this other player, we use this for loop to exclude the "$" key
	for path in all_input:
		# skip the dollar sign key (aka the input comparison hash)
		if path == "$":
			continue
	
		# we now need to know which player is sending the input
			# in our case, we know it is either the /root/main_scene/Players/Player1, /root/main_scene/Players/Player2, etc etc...
			# since we only have 4 total possibilities, we can send an integer between 1-4 over for this
			# this saves us from sending the whole ass path string over the network and instead sending over a single byte
			# input_path_mapping[path] will be an integer 1-4, which is then written into the buffer
		buffer.put_u8(input_path_mapping[path])
		
		# serialize the individual input for every player
		# NOTE: the player_input dictionary is the same one we created in the RollbackCharacterController.gd script
		var player_input = all_input[path]
		per_player_serialize_input(buffer, player_input)
	# -- end of for loop
	
	# ---------- END BUFFER WRITING --------- #
	
	# this line sets the buffer it it's ACTUAL size after we added stuff
	buffer.resize(buffer.get_position())
	if DEBUG_OUTPUT:
		print("ending buffer size: ", buffer.get_position())
	return buffer.data_array
## end serialize_input method

# -------------------- OPTIMIZED VERSION: UNSERIALIZING DATA --------------------- #


func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	
	# create a new byte buffer
	var buffer := StreamPeerBuffer.new()
	
	# put our serialized data into our new buffer
	buffer.put_data(serialized)
	
	# start our search at the start of the buffer
	buffer.seek(0)
	
	# what we will return at the end
	var all_input := {}
	
	# retrieve our buffer hash and put it back into our dictionary
		# get the 32 bit integer we stored at the start of our buffer
		# this will also shift our buffer's cursor over 4 bytes
	all_input["$"] = buffer.get_u32()
	
	# now we need to get how many player inputs we have in this message
		# if we are getting no inputs, then we can return early
	var players_inputting = buffer.get_u8()
	#print(players_inputting)
	if players_inputting == 0:
		return all_input
		
	# obtain the player's node path
	var path_key = buffer.get_u8()
	var path = input_path_mapping_reverse[path_key]
	
	# now lets gather the individual input
	var player_input := {}
	var has_input_header = buffer.get_u8()
	
	# use an and gate to check if the header is true (this is "truthy")
	if has_input_header & HeaderFlags.TARGET_CHANGE_INPUT:
		player_input["pressed_change_target"] = true
	if has_input_header & HeaderFlags.TARGET_INPUT:
		player_input["pressed_target"] = true
	if has_input_header & HeaderFlags.BLOCK_HOLD_INPUT:
		player_input["holding_block"] = true
	if has_input_header & HeaderFlags.JUMP_INPUT:
		player_input["pressed_jump"] = true
	if has_input_header & HeaderFlags.HAS_INPUT_VECTOR:
		player_input["input_vector"] = Vector2(buffer.get_float(), buffer.get_float())
	if has_input_header & HeaderFlags.HOLDING_MOVE_INPUT:
		var move_header = buffer.get_u8()
		if move_header & MoveFlags.NORMAL_CLOSE:
			player_input["normal_close"] = true
		if move_header & MoveFlags.NORMAL_FAR:
			player_input["normal_far"] = true
		if move_header & MoveFlags.SPECIAL_CLOSE:
			player_input["special_close"] = true
		if move_header & MoveFlags.SPECIAL_FAR:
			player_input["special_far"] = true
	
	# add our new input to the dictionary and return
	all_input[path] = player_input
	return all_input
## end unserialize_input method
