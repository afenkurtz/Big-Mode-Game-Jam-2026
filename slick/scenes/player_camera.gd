extends Camera3D

# Camera position
@export_group("Positioning")
@export var camera_distance_from_player = 12.0  # Total distance from player
@export var camera_pitch_angle = 65.0  # Angle from horizontal (higher = more top-down)

# Following behavior
@export_group("Follow Settings")
@export var follow_speed = 8.0
@export var rotation_speed = 5.0
@export var look_ahead_strength = 0.0  # Lowered from 0.3

# Smoothing
@export_group("Smoothing")
@export var use_position_smoothing = true
@export var use_rotation_smoothing = true

var player = null
var target_position = Vector3.ZERO
var target_look_at = Vector3.ZERO

func _ready():
	player = get_parent()
	
	if player:
		update_target_position()
		global_position = target_position
		look_at(player.global_position + Vector3(0, 1, 0), Vector3.UP)

func _process(delta):
	if not player:
		return
	
	update_target_position()
	update_camera(delta)

func update_target_position():
	# Calculate position based on angle and distance
	var angle_rad = deg_to_rad(camera_pitch_angle)
	
	# Height and horizontal distance from angle
	var height = sin(angle_rad) * camera_distance_from_player
	var horizontal = cos(angle_rad) * camera_distance_from_player
	
	# Look-ahead (reduced)
	var look_ahead = Vector3.ZERO
	if "velocity" in player and look_ahead_strength > 0:
		look_ahead = Vector3(player.velocity.x, 0, player.velocity.z) * look_ahead_strength
	
	# Position camera behind and above player
	target_position = player.global_position + Vector3(0, height, horizontal)
	target_look_at = player.global_position + Vector3(0, 1, 0) + look_ahead

func update_camera(delta):
	# Smooth position follow
	if use_position_smoothing:
		global_position = global_position.lerp(target_position, follow_speed * delta)
	else:
		global_position = target_position
	
	# Smooth rotation
	if use_rotation_smoothing:
		var current_transform = global_transform
		var target_transform = global_transform.looking_at(target_look_at, Vector3.UP)
		global_transform = current_transform.interpolate_with(target_transform, rotation_speed * delta)
	else:
		look_at(target_look_at, Vector3.UP)
