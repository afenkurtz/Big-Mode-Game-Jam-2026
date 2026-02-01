extends CharacterBody3D

# Movement parameters
@export var chase_force = 200.0
@export var friction_coefficient = 0.95
@export var ground_friction = 0.98
@export var max_speed = 25.0
@export var chase_distance = 50.0
@export var attack_range = 2.0

# Homing parameters
@export var homing_strength = 5.0  # How aggressively it turns toward player
@export var homing_distance = 15.0  # Distance at which homing activates

# Health
@export var max_health = 100.0
var current_health = max_health

# Physics
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Player reference
var player: CharacterBody3D = null

func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("Warning: No player found!")
	else:
		print("Enemy found player: ", player.name)
	
	add_to_group("enemy")

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Chase and home in on player
	if player != null:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player < chase_distance and distance_to_player > attack_range:
			# Calculate direction to player
			var direction = (player.global_position - global_position).normalized()
			direction.y = 0  # Keep movement horizontal
			
			# If within homing range, apply strong homing
			if distance_to_player < homing_distance:
				# Homing missile behavior - aggressively turn toward player
				var current_direction = Vector3(velocity.x, 0, velocity.z).normalized()
				
				# Blend current direction with target direction
				var new_direction = current_direction.lerp(direction, homing_strength * delta)
				new_direction = new_direction.normalized()
				
				# Maintain current speed but change direction
				var current_speed = Vector2(velocity.x, velocity.z).length()
				velocity.x = new_direction.x * current_speed
				velocity.z = new_direction.z * current_speed
				
				# Add acceleration toward player
				velocity.x += direction.x * chase_force * delta * 0.5
				velocity.z += direction.z * chase_force * delta * 0.5
				
				print("HOMING! Speed: ", current_speed)
			else:
				# Normal chase outside homing range
				velocity.x += direction.x * chase_force * delta
				velocity.z += direction.z * chase_force * delta
		
		elif distance_to_player <= attack_range:
			# Within attack range
			pass
	
	# Apply friction
	if is_on_floor():
		velocity.x *= friction_coefficient * ground_friction
		velocity.z *= friction_coefficient * ground_friction
	else:
		velocity.x *= friction_coefficient
		velocity.z *= friction_coefficient
	
	# Cap maximum speed
	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	if horizontal_velocity.length() > max_speed:
		horizontal_velocity = horizontal_velocity.normalized() * max_speed
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.y
	
	move_and_slide()

func take_damage(amount: float):
	current_health -= amount
	print("Enemy took ", amount, " damage. Health: ", current_health)
	
	flash_red()
	
	if current_health <= 0:
		die()

func flash_red():
	var mesh = $MeshInstance3D
	if mesh:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.RED
		mesh.material_override = material
		
		await get_tree().create_timer(0.1).timeout
		if mesh and is_instance_valid(self):
			mesh.material_override = null

func die():
	print("Enemy died!")
	queue_free()
