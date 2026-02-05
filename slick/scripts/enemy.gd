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

# Health Parameters
@export var max_health = 100.0
var current_health = max_health

# Attack Parameters
@export var attack_damage = 15.0
@export var attack_cooldown = 1.5
@export var knockback_strength = 100.0
var attack_timer = 0.0

# Stun system
@export var stun_duration = 0.8  # How long enemies are stunned
var is_stunned = false
var stun_timer = 0.0

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
	# Update stun timer
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			
			var mesh = $MeshInstance3D
			if mesh:
				mesh.material_override = null
				
	
	# Update attack cooldown
	if attack_timer > 0 :
		attack_timer -= delta
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Try to find player if we don't have a reference yet
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			move_and_slide()
			return
			
		# Skip AI if stunned
	if is_stunned:
		if is_on_floor():
			velocity.x *= friction_coefficient * ground_friction
			velocity.z *= friction_coefficient * ground_friction
		else:
			velocity.x *= friction_coefficient
			velocity.z *= friction_coefficient
		
		move_and_slide()
		return
	
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
				
				#print("HOMING! Speed: ", current_speed)
			else:
				# Normal chase outside homing range
				velocity.x += direction.x * chase_force * delta
				velocity.z += direction.z * chase_force * delta
		
		elif distance_to_player <= attack_range:
			# Within attack range
			if attack_timer <= 0:
				perform_melee_attack()
				attack_timer = attack_cooldown
	
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

func take_damage(amount: float, attacker_position: Vector3 = Vector3.ZERO):
	current_health -= amount
	print("Enemy took ", amount, " damage. Health: ", current_health)
	
	if attacker_position != Vector3.ZERO:
		var knockback_dir = (global_position - attacker_position).normalized()
		knockback_dir.y = 0  # Keep horizontal
		
		# Apply knockback force to velocity
		velocity.x += knockback_dir.x * knockback_strength
		velocity.z += knockback_dir.z * knockback_strength
		print("Enemy knockback applied!")
		
		# Apply stun when knocked back
		is_stunned = true
		stun_timer = stun_duration
		print("Enemy stunned for", stun_duration, " seconds!")
		
		apply_stun()
		
	flash_red()
	
	if current_health <= 0:
		die()

func perform_melee_attack():
	print("Enemy melee attack")
	
	#Check if the player is still in range
	if player !=null and global_position.distance_to(player.global_position) <= attack_range:
		# Damage the player
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, global_position) # pass enemy position
			print("Hit player for ", attack_damage, " damage!")
			

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

func apply_stun():
	is_stunned = true
	stun_timer = stun_duration
	
	#visual feedback
	spawn_stun_stars()

func spawn_stun_stars():
	# create circling stars above enemy
	for i in range(3):
		var star = MeshInstance3D.new()
		add_child(star)
		
		var star_mesh = SphereMesh.new()
		star_mesh.radius = 0.2
		star.mesh = star_mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1,1,0)
		material.emission_enabled = true
		material.emission = Color(1,1,0)
		star.material_override = material
		#position above head
		star.position = Vector3(0,2,0)
		# Animate circling
		var tween = create_tween()
		tween.set_loops(int(stun_duration * 2))
		tween.tween_property(star,"rotation:y", TAU, 0.5)
		# Cleanup
		get_tree().create_timer(stun_duration).timeout.connect(
			func():
				if is_instance_valid(star):
					star.queue_free()
		)
