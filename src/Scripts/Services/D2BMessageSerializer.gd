#Kyle Senebouttarath

extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

# -------------------- CONSTANTS --------------------- #

# player number + input header + WASD vector
const PLAYER_INPUT_SIZE : int = 1 + 1 + 8
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
	# if we need more flags, we should go up in increments (0x01, 0x02, 0x04, 0x08, 0x10, etc)
	# the purpose of doing it this is that it allows us to send multiple input states in a single byte for the header
	# this is VERY SIMILAR to how it is done with our robot in Real-Time Systems
enum HeaderFlags {
	# this is a single byte
	HAS_INPUT_VECTOR = 0x01,
	#DROP_BOMB = 0x02,
}

func per_player_serialize_input(buffer, player_input) -> void:
	var header := 0
	
	# if they have an input vector
	if player_input.has("input_vector"):
		# bitwise OR assignment being performed on the header value (0) and the HAS_INPUT_VECTOR enum (0x01)
		# this value is then assigned into the header variable (aka we flipped it to be 0x01 now)
		# the |= can be used to essentially "append" more header data into the the header
		header |= HeaderFlags.HAS_INPUT_VECTOR
		
	#if input.has("dropBomb"):
	#	header |= HeaderFlags.DROP_BOMB
		
	# now we write a single byte for our header to indicate that our input_vector exists or not
	buffer.put_u8(header)
	
	# now we write the data if it exists
	if player_input.has("input_vector"):
		var input_vector: Vector2 = player_input["input_vector"]
		
		# this writes 4 bytes for the X value and 4 bytes for the Y value
		buffer.put_float(input_vector.x)
		buffer.put_float(input_vector.y)
	


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
	if players_inputting == 0:
		return all_input

	# obtain the player's node path
	var path_key = buffer.get_u8()
	var path = input_path_mapping_reverse[path_key]

	# now lets gather the individual input
	var player_input := {}
	var has_input_header = buffer.get_u8()
	# use an and gate to check if the header is true (this is "truthy")
	if has_input_header & HeaderFlags.HAS_INPUT_VECTOR:
		player_input["input_vector"] = Vector2(buffer.get_float(), buffer.get_float())
#	if hasInputHeader & HeaderFlags.DROP_BOMB:
#		input["dropBomb"] = true
	
	# add our new input to the dictionary and return
	all_input[path] = player_input
	return all_input
## end unserialize_input method
