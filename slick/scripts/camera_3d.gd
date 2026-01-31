extends Camera3D

var player: CharacterBody3D

func _ready():
	# Get the parent player node
	player = get_parent()
	
	# Safety check
	if player == null:
		push_error("Camera must be a child of the Player node!")

func _process(delta):
	# Make sure player exists before trying to use it
	if player == null:
		return
	
	# Smooth camera follow with slight lag
	global_position = global_position.lerp(
		player.global_position + Vector3(0, 2, 5),
		5.0 * delta
	)
	look_at(player.global_position, Vector3.UP)
