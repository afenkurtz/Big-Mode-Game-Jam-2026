extends CharacterBody3D

@export var chase_force = 50 # how quickly the enemy will move toward the player
@export var friction_coefficient = 0.99
@export var ground_friction = 0.96
@export var max_speed = 35.0
@export var chase_distance = 50.0
@export var attack_range = 2.0

#health
@export var max_health = 100.0
var current_health = max_health

#physics - gravity (uses godot defaults)
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#player reference - used to allow the enemy to chase the players position
var player: CharacterBody3D = null

func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")
	
	# Debug collision setup
	print("=== ENEMY SETUP ===")
	print("Enemy name: ", name)
	print("Enemy position: ", global_position)
	print("Collision layer: ", collision_layer)
	print("Collision mask: ", collision_mask)
	
	if has_node("CollisionShape3D"):
		var col_shape = $CollisionShape3D
		print("Has collision shape: YES")
		print("Shape type: ", col_shape.shape)
		print("Shape disabled: ", col_shape.disabled)
	else:
		print("ERROR: NO COLLISION SHAPE FOUND!")
	print("===================")
		
func _physics_process(delta):
	#apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	#checks if player is in range, if player is in range, chase player
	if player != null:
		var distance_to_player = global_position.distance_to(player.global_position)
		#print("Distance: ", distance_to_player, " | Chase distance: ", chase_distance, " | Attack range: ", attack_range)
		if distance_to_player < chase_distance and distance_to_player > attack_range:
			# Predict where player will be
			var time_to_reach = distance_to_player / max_speed
			var predicted_position = player.global_position + player.velocity * time_to_reach * 0.5
	
			# Calculate direction to predicted position
			var direction = (predicted_position - global_position).normalized()
			direction.y = 0
	
			velocity.x += direction.x * chase_force * delta
			velocity.z += direction.z * chase_force * delta
			
			#print("velocity: ", velocity)
			
			
		elif distance_to_player <= attack_range:
		#this is where attack logic will go
			pass
			
	if is_on_floor():
		velocity.x *= friction_coefficient * ground_friction
		velocity.z *= friction_coefficient * ground_friction
	else:
		velocity.x *= friction_coefficient
		velocity.z *= friction_coefficient
			
		#cap maximum speed
		var horizontal_velocity = Vector2(velocity.x, velocity.z)
		if horizontal_velocity.length() > max_speed:
			horizontal_velocity = horizontal_velocity.normalized() * max_speed
			velocity.x = horizontal_velocity.x
			velocity.z = horizontal_velocity.y
			
	# Move the character

	move_and_slide()

		
func take_damage(amount: float):
	current_health -= amount
	print("Enemy took ", amount, " damage, Health: ", current_health)
	
	#visual feedback for hit
	flash_red()
		
	if current_health <= 0:
		die()
	
func flash_red():
	var mesh = $MeshInstance3D
	if mesh:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.RED
		mesh.material_override = material
		
	#reset mesh color after delay
	await get_tree().create_timer(0.1).timeout
	mesh.material_override = null
	
func die():
	print("Enemy died!")
	queue_free()
		
