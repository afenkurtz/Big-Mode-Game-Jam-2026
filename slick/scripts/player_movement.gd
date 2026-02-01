extends CharacterBody3D

# Movement parameters
@export var burst_force = 20.0
@export var friction_coefficient = .98
@export var ground_friction = 1
@export var max_speed = 30.0

#attack parameters
@export var stab_range = 6.0
@export var stab_damage = 25.0
@export var stab_charge_multiplier = 2.0
@export var max_charge_time = 1.0
@export var projectile_speed = 40.0
@export var projectile_scene: PackedScene #assign in inspector

@export var debug_visuals = true 

#combo system
@export var combo_window = 1.0 # time window to continue attack
var combo_count = 0 # current hit in combo 0,1,2
var combo_timer = 0.0 # time since last attack

#charging system
var is_charging_stab = false
var charge_start_time = 0.0
var charge_amount = 0.0 # 0 - 1

# Physics
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Camera reference
@onready var camera = $Camera3D

func _physics_process(delta):
	# update combo timer
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			#combo window expired, new window
			combo_count = 0
			print("Combo Reset")
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta/1.5
	
	# Get mouse position in world space
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	# Raycast to find where mouse points on ground plane
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	# Handle burst toward mouse
	if Input.is_action_just_pressed("move_forward") and result:
		
		var target_pos = result.position
		var direction = (target_pos - global_position).normalized()
		direction.y = 0  # Keep movement horizontal
		
		velocity.x += direction.x * burst_force
		velocity.z += direction.z * burst_force
		perform_stab(direction)
		print("Boosting toward: ", direction)
	
	# Optional: backward burst (away from mouse)
	if Input.is_action_just_pressed("fire_gun") and result:
		var target_pos = result.position
		var direction = (global_position - target_pos).normalized()
		direction.y = 0
		
		velocity.x += direction.x * burst_force
		velocity.z += direction.z * burst_force
		fire_projectile(direction * -1)
	
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

func perform_stab(direction: Vector3):
	print("=== STAB DEBUG ===")
	
	var space_state = get_world_3d().direct_space_state
	var stab_duration = 0.125  # How long the hitbox stays active
	var hit_enemies = []  # Track which enemies we've already hit
	
	# Create a capsule shape for detection
	var shape = CapsuleShape3D.new()
	shape.radius = 0.6
	shape.height = 2.25
	
	# Rotate capsule to point in stab direction
	var look_basis = Basis.looking_at(direction, Vector3.UP)
	look_basis = look_basis.rotated(look_basis.x, PI / 2.0)
	
	# VISUAL DEBUG - Show the capsule that follows player
	var debug_capsule = null
	if debug_visuals:
		debug_capsule = MeshInstance3D.new()
		add_child(debug_capsule)
		
		var capsule_mesh = CapsuleMesh.new()
		capsule_mesh.radius = shape.radius
		capsule_mesh.height = shape.height
		debug_capsule.mesh = capsule_mesh
		
		# Set LOCAL position relative to player
		var local_offset = direction * (stab_range / 3.0)
		debug_capsule.position = Vector3(0, 1, 0) + local_offset
		debug_capsule.transform.basis = look_basis
		
		# Make it semi-transparent red
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 0, 0, 0.3)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		debug_capsule.material_override = material
	
	# Create a timer to track elapsed time
	var elapsed = 0.0
	var check_interval = 0.05  # Check every 0.05 seconds (20 times per second)
	
	# Keep checking for hits while the stab is active
	while elapsed < stab_duration:
		await get_tree().create_timer(check_interval).timeout
		elapsed += check_interval
		
		# Check if player still exists (in case they die during stab)
		if not is_instance_valid(self):
			break
		
		# Update hitbox position to follow player
		var stab_start = global_position + Vector3(0, 1, 0)
		var stab_center = stab_start + direction * (stab_range / 3.0)
		var capsule_transform = Transform3D(look_basis, stab_center)
		
		# Check for collisions at current position
		var params = PhysicsShapeQueryParameters3D.new()
		params.shape = shape
		params.transform = capsule_transform
		params.collision_mask = 1
		params.exclude = [self]
		
		var results = space_state.intersect_shape(params)
		
		# Check each result
		for result in results:
			if result.collider.is_in_group("enemy"):
				# Only hit each enemy once per stab
			
				if not hit_enemies.has(result.collider):
					var to_enemy = (result.collider.global_position - global_position).normalized()
					var dot = direction.dot(to_enemy)
					
					if dot > 0.5:
						print("Hit enemy: ", result.collider.name)
						if result.collider.has_method("take_damage"):
							result.collider.take_damage(stab_damage)
							hit_enemies.append(result.collider)
							
							# Turn capsule green on hit
							if debug_capsule and is_instance_valid(debug_capsule):
								var hit_material = StandardMaterial3D.new()
								hit_material.albedo_color = Color(0, 1, 0, 0.5)
								hit_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
								debug_capsule.material_override = hit_material
			elif result.collider.is_in_group("breakable"):
				if not hit_enemies.has(result.collider):
					print ("Hit breakable object: ", result.collider.name)
					if result.collider.has_method("take_damage"):
						result.collider.take_damage(stab_damage)
						hit_enemies.append(result.collider)
	
	# Clean up debug visual
	if debug_capsule and is_instance_valid(debug_capsule):
		debug_capsule.queue_free()
	
	print("Stab finished. Hit ", hit_enemies.size(), " enemies")
	print("==================")

		
func fire_projectile(direction: Vector3):
	print("=== FIRING PROJECTILE ===")
	print("Direction: ", direction)
	
	if projectile_scene == null:
		print("Warning: No projectile scene assigned!")
		return
	
	# Spawn projectile
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	
	# Position it in front of player
	var spawn_offset = direction * 1.0
	projectile.global_position = global_position + Vector3(0, 1, 0) + spawn_offset
	
	print("Projectile spawned at: ", projectile.global_position)
	
	# Set projectile velocity
	if projectile.has_method("set_velocity"):
		projectile.set_velocity(direction * projectile_speed)
	elif "velocity" in projectile:
		projectile.velocity = direction * projectile_speed
	
	print("======================")
	
func _ready():
	print("Player initialized with mouse control")
