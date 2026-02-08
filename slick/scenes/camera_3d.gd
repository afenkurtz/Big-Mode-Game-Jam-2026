extends Camera3D

@export var base_fov = 75.0
@export var boost_fov = 85.0

# Base camera settings (when stationary)
@export_group("Base Position")
@export var base_distance = 10.0  # Distance behind player when stopped
@export var base_height = 15.0    # Height above player when stopped
@export var base_pitch = -50.0    # Looking down angle when stopped (degrees)

# Dynamic adjustments (when moving at max/boost speed)
@export_group("Speed Adjustments")
@export var max_distance_offset = 3.0   # How much farther back at max speed
@export var max_height_offset = 2.0     # How much higher at max speed
@export var max_pitch_offset = 4.0      # How much more upward angle (3-5 degrees)

# Smoothing
@export_group("Smoothing")
@export var position_smooth_speed = 5.0  # How fast camera follows position
@export var rotation_smooth_speed = 3.0  # How fast camera adjusts angle
@export var speed_response = 8.0         # How fast camera responds to speed changes
var shake_amount = 0.0

# Reference speeds (from player)
@export_group("Player Speed Reference")
@export var player_max_speed = 30.0   # Player's normal max speed
@export var player_boost_speed = 60.0 # Player's boost speed

var player = null
var current_speed_ratio = 0.0  # 0 = stopped, 1 = boost speed

func _ready():
	player = get_parent()
	
	if player:
		print("Dynamic camera attached to: ", player.name)
		setup_initial_position()

func setup_initial_position():
	# Set initial position and look at player
	position = Vector3(0, base_height, base_distance)
	look_at(player.global_position + Vector3(0, 1, 0), Vector3.UP)

func _process(delta):
	if not player:
		return
		
	# Camera shake while boosting
	if player.is_boosting and shake_amount < 0.2:
		shake_amount = 0.2
	
	if shake_amount > 0:
		shake_amount = max(shake_amount - delta * 2.0, 0)
		var shake = Vector3(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount),
			0
		)
		position += shake
	
	update_camera_dynamic(delta)

func update_camera_dynamic(delta):
	# Get player's current speed
	var player_velocity = Vector2(player.velocity.x, player.velocity.z)
	var current_speed = player_velocity.length()
	
	# Calculate speed ratio (0 = stopped, 1 = boost speed)
	var target_speed_ratio = clamp(current_speed / player_boost_speed, 0.0, 1.0)
	
	# Smooth the speed ratio for gradual camera movement
	current_speed_ratio = lerp(current_speed_ratio, target_speed_ratio, speed_response * delta)
	
	# Calculate dynamic offsets based on speed
	var dynamic_distance = base_distance + (max_distance_offset * current_speed_ratio)
	var dynamic_height = base_height + (max_height_offset * current_speed_ratio)
	var dynamic_pitch = base_pitch + (max_pitch_offset * current_speed_ratio)
	
	# Calculate target position
	var target_position = Vector3(0, dynamic_height, dynamic_distance)
	
	# Smooth position follow
	position = position.lerp(target_position, position_smooth_speed * delta)
	
	# Calculate look-at point slightly ahead of player
	var look_ahead = Vector3.ZERO
	if player_velocity.length() > 0.1:
		look_ahead = Vector3(player.velocity.x, 0, player.velocity.z).normalized() * 2.0
	
	var look_target = player.global_position + Vector3(0, 1, 0) + look_ahead
	
	# Smooth rotation to look at target
	var target_transform = global_transform.looking_at(look_target, Vector3.UP)
	global_transform = global_transform.interpolate_with(target_transform, rotation_smooth_speed * delta)
	
	# Apply dynamic pitch adjustment
	var current_rotation = rotation_degrees
	current_rotation.x = lerp(current_rotation.x, dynamic_pitch, rotation_smooth_speed * delta)
	rotation_degrees = current_rotation
	
	var target_fov = lerp(base_fov, boost_fov, current_speed_ratio)
	fov = lerp(fov, target_fov, 3.0 * delta)

func _input(event):
	# Optional: Mouse wheel zoom (hold Ctrl while scrolling)
	if event is InputEventMouseButton and Input.is_key_pressed(KEY_CTRL):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			base_distance = clamp(base_distance - 1.0, 8.0, 30.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			base_distance = clamp(base_distance + 1.0, 8.0, 30.0)
