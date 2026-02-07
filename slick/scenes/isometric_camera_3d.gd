extends Camera3D

# Camera settings
@export_group("Position")
@export var camera_distance = 20.0
@export var camera_height = 15.0
@export var camera_angle = 50.0 # Degrees from horizontal

@export_group("Follow")
@export var follow_speed = 8.0
@export var look_ahead_factor = 0.3 # 0-1, how much to lead player movement

var player = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent()
	setup_camera_position()
	
func setup_camera_position():
	# Calculate position based on distance, height, and angle
	var angle_rad = deg_to_rad(camera_angle)
	var horizontal_distance = camera_height / tan(angle_rad)
	
	position = Vector3(0, camera_height, horizontal_distance)
	look_at(Vector3(0,0,0), Vector3.UP)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player:
		return
		
	#Slight Camera lead based on player velocity
	var lead_offset = Vector3.ZERO
	if "velocity" in player:
		lead_offset = Vector3(player.velocity.x, 0, player.velocity.z)
		lead_offset.y = 0
		
	#smooth follow
	var target_look = player.global_position + lead_offset
	var current_look = global_position +(-global_transform.basis.z * camera_distance)
	#var smooth_look = current_look.lerp(target_look, follow_speed * delta)
	
	#look_at(smooth_look, Vector3.UP)
