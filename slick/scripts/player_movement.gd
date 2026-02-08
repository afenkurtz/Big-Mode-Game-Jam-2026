extends CharacterBody3D
# @onready var character_model = $"Protag_Sit-Static" #Change this if the name of the model changes
@onready var pivot = $Pivot

var animation_tree: AnimationTree

# Movement parameters
@export var burst_force = 20.0
@export var friction_coefficient = .98
@export var ground_friction = 1
@export var max_speed = 30.0
@export var rotation_speed = 10.0

#attack parameters
@export var stab_range = 6.0
@export var stab_damage = 25.0
@export var projectile_speed = 35.0
@export var projectile_scene: PackedScene #assign in inspector
@export var knockback_force = 15.0 # Adjustable value
@export var debug_visuals = true 

# Ammo system
@export var max_ammo = 6.0
@export var ammo_per_hit = .34 # Gain 1/3 of an ammo per hit (3 hits = 1 full ammo
var current_ammo = 6.0

#combo system
@export var combo_window = .25 # time window to continue attack
@export var combo_cooldown = 0.60 # Cooldown after completing a 3 hit combo
var combo_count = 0 # current hit in combo 0,1,2
var combo_timer = 0.0 # time since last attack
var is_in_cooldown = false # Tracks if we're in post-combo cooldown

# Health
@export var max_health = 100.0
@export var invulnerability_duration = 1.0

#Coin system
var coins_collected = 0


var is_invulnerable = 1.0
var invulnerability_timer = 1.0
var current_health = max_health

# Boost system
var is_boosting = false
var boost_decel_rate = 1.0 # closer to 1 = slower decay

# Physics
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Camera reference
@onready var camera = $Camera3D

func _physics_process(delta):
	
	# Update invlunerability timer
	if invulnerability_timer > 0:
			invulnerability_timer -= delta
			if invulnerability_timer <= 0:
				is_invulnerable = false
				print ("Invulnerability ended")
	
	# update combo timer
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			if is_in_cooldown:
				# Cooldown finished
				is_in_cooldown = false
				#combo window expired, new window
				combo_count = 0
				print("Combo Reset")
			else:
				# Combo window expired, reset counternot is_in_cooldown and (combo_count == 0 or combo_timer > 0):
				combo_count = 0
				print("Combo reset")
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Get mouse position in world space
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	# Raycast to find where mouse points on ground plane
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	var direction = Vector3.ZERO
	if result: #ensures raycast hits ground
		var target_pos = result.position
		direction = (target_pos - global_position).normalized()
		direction.y=0
		# Rotate character model to face cursor
		rotate_character_to_cursor(direction)
			
	if direction.length() > 0.1:
		#Rotate character and handle movement
		rotate_character_to_cursor(direction)
	else:
		if velocity.length() > 0.1:
			direction = Vector3(velocity.x, 0, velocity.z).normalized()
	
	# Handle burst toward mouse
	if Input.is_action_just_pressed("move_forward") and result:
		# Check if we can attack (combo system)
		var can_attack = not is_in_cooldown and (combo_count == 0 or combo_timer > 0)
		
		if can_attack:
			#Perform stab
			perform_stab(direction)
			#Perform stab anim
			perform_stab_anim(combo_count+1)
			
			#apply movement in the same direction
			velocity.x += direction.x * burst_force
			velocity.z += direction.z * burst_force
			
			# Update combo
			combo_count += 1
			print("Stab #", combo_count, " of 3")
			
			if combo_count >= 3:
				# reset anim
				animation_tree.set("parameters/Transition/transition_request", "moving")
				print("Combo complete! Cooldown starting...")
				is_in_cooldown = true
				combo_timer = combo_cooldown # Start cooldown timer
			else:
				# Continue combo - give time window for next attack
				combo_timer = combo_window
				print("You have ", combo_window, " seconds for next attack")
		else:
			if is_in_cooldown:
				print ("In cooldown! Wait ", combo_timer, " more seconds")
			else:
				print("Combo window expired! Can't attack yet.")
	
#backward burst (away from mouse)
	if Input.is_action_just_pressed("fire_gun") and result:
		# Checks to see if we have ammo
		if current_ammo >= 1.0:
			#fire projectile
			fire_projectile(direction)
			
			# Consumes ammo
			current_ammo -= 1.0
			print ("Fired projectile! Ammo: ", current_ammo, "/", max_ammo)
			# Apply Backward Force
			var backward_dir = -direction
			velocity.x += backward_dir.x * burst_force
			velocity.z += backward_dir.z * burst_force
		else:
			print("Out of ammo! Hit enemies to restore.")
			# TODO: Add audio feedback
	
	# Apply friction
	if is_on_floor():
		velocity.x *= friction_coefficient * ground_friction
		velocity.z *= friction_coefficient * ground_friction
	else:
		velocity.x *= friction_coefficient
		velocity.z *= friction_coefficient
	
	# Cap maximum speed
	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	var current_speed = horizontal_velocity.length()
	
	if is_boosting:
		#while boosting, decelerate
		if current_speed > max_speed:
			# apply boost decay
			velocity.x *= boost_decel_rate
			velocity.z *= boost_decel_rate
		else:
			#once at normal speed, disable boost
			is_boosting = false
			is_invulnerable = false
			invulnerability_timer = 0.0
	else:
		#normal speed cap
		if current_speed > max_speed:
			horizontal_velocity = horizontal_velocity.normalized() * max_speed
			velocity.x = horizontal_velocity.x
			velocity.z = horizontal_velocity.y
			

	move_and_slide()
	preserve_wall_momentum_with_boost()
	
	# Preserve/boost momentum when hitting walls
func preserve_wall_momentum_with_boost():
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()
		
		#Only handle wall collisions
		if abs(normal.y) < 0.5:
			var velocity_2d = Vector3(velocity.x, 0 , velocity.z)
			var speed = velocity_2d.length()
			
			if speed > 0.1: # Only if actually moving
				# Deflect velocity along wall with slight boost
				var deflected = velocity_2d - normal * velocity_2d.dot(normal)
				deflected = deflected.normalized() * speed * 1.02 # 2% boost to compensate for losses
			
				velocity.x = deflected.x
				velocity.z = deflected.z
			return
	
	if is_boosting:
		check_boost_collisions()
		
func check_boost_collisions():
	# check collision during boost
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("enemy") and collider.is_in_group("breakable"):
			print("Boost collision into enemy")
			
			# Damage the enemy
			if collider.has_method("take_damage"):
				collider.take_damage(50.0, global_position)
				print("dealt 50 boost damage to enemy")
				
		# Extra knockback for boost collision
		if "velocity" in collider:
			var knockback_dir = (collider.global_position - global_position).normalized()
			knockback_dir.y = 0
			
			# Strong knockback
			var boost_knockback = 30.0
			collider.velocity.x += knockback_dir.x * boost_knockback
			collider.velocity.z += knockback_dir.z * boost_knockback

func perform_stab(direction: Vector3):
	print("=== STAB DEBUG ===")
	
	var space_state = get_world_3d().direct_space_state
	var stab_duration = 0.125  # How long the hitbox stays active
	var hit_objects = []  # Track which enemies we've already hit
	
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
				if not hit_objects.has(result.collider):
					var to_enemy = (result.collider.global_position - global_position).normalized()
					var dot = direction.dot(to_enemy)
				# Only hit each enemy once per stab
					
					if dot > 0.5:
						print("Hit enemy: ", result.collider.name)
						if result.collider.has_method("take_damage"):
							result.collider.take_damage(stab_damage, global_position)
							hit_objects.append(result.collider)
							
							#restore ammo if at 5 or fewer shots
							if current_ammo <= 5.0:
								current_ammo = min(current_ammo + ammo_per_hit, max_ammo)
								print ("Ammo: ", current_ammo, "/", max_ammo)
							
							# Turn capsule green on hit
							if debug_capsule and is_instance_valid(debug_capsule):
								var hit_material = StandardMaterial3D.new()
								hit_material.albedo_color = Color(0, 1, 0, 0.5)
								hit_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
								debug_capsule.material_override = hit_material
			elif result.collider.is_in_group("breakable"):
				if not hit_objects.has(result.collider):
					print ("Hit breakable object: ", result.collider.name)
					if result.collider.has_method("take_damage"):
						result.collider.take_damage(stab_damage)
						hit_objects.append(result.collider)
	
	# Clean up debug visual
	if debug_capsule and is_instance_valid(debug_capsule):
		debug_capsule.queue_free()
	
	print("Stab finished. Hit ", hit_objects.size(), " enemies")
	print("==================")

func perform_stab_anim(combo_num: int):
	$AttackSound.play()
	
	# theres a better way to do this 
	# oh well
	if combo_num == 3:
		# Set animation tree condition is_melee_3 to true
		play_animation("sit_stab_3")
	elif combo_num == 2:
		play_animation("sit_stab_2")
	else:
		play_animation("sit_stab_1")


		
func fire_projectile(direction: Vector3):
	print("=== FIRING PROJECTILE ===")
	print("Direction: ", direction)
	
	$GunSound.play()
	play_animation("sit_shoot")
	
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
	current_health = max_health
	current_ammo = max_ammo
	coins_collected = 0
	print ("Player health: ", current_health)
	print ("Player ammo: ", current_ammo)
	
	wall_min_slide_angle = 0.0
	floor_stop_on_slope = false
	floor_block_on_wall = false
	
	animation_tree = $AnimationTree
	animation_tree.connect("animation_finished", _on_animation_finished)
	
func add_coins(amount: int):
	coins_collected += amount
	print(coins_collected)
	
	
func _on_animation_finished(anim_name: String):
	if anim_name in ["sit_shoot", "sit_stab_1", "sit_stab_2", "sit_stab_3"]:
		animation_tree["parameters/playback"].travel("sit_idle")
		
func play_animation(anim_name: String):
	animation_tree["parameters/playback"].travel(anim_name)
	
func heal(amount: float) -> float:
	var old_health = current_health
	current_health = min(current_health + amount, max_health)
	var actual_heal = current_health - old_health
	
	return actual_heal
	
func apply_boost(direction: Vector3, speed:float):
	print("Boost! Speed: ", speed)
	
	#preserve y velocity
	var current_y_velocity = velocity.y
	
	#set velocity in boost direction
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = current_y_velocity
	
	#Enter boost state
	is_boosting = true
	
	#activate invulnerability
	is_invulnerable = true
	invulnerability_timer = invulnerability_duration
	flash_invulnerable()
	

func take_damage(amount: float, attacker_position: Vector3 = Vector3.ZERO):
	if is_invulnerable:
		print("Player is invulnerable - no damage taken")
		return
	
	current_health -= amount
	print("Player took ", amount, " damage! Health: ", current_health)
	
	# Apply knockback if attacker position is provided
	if attacker_position != Vector3.ZERO:
		var knockback_dir = (global_position - attacker_position).normalized()
		knockback_dir.y = 0
		

		velocity.x += knockback_dir.x * knockback_force
		velocity.z += knockback_dir.z * knockback_force
		print("Player knockback applied")
	
	is_invulnerable = true
	invulnerability_timer = invulnerability_duration
	print("Invulnerability active for ", invulnerability_duration, "seconds")
	
	$HitSound.play()
	flash_invulnerable()
	
	if current_health <= 0:
		die()
		
func flash_invulnerable():
	var mesh = $Pivot/Protag_Main/Armature/Skeleton3D/Body
	if mesh:
		#flash between normal and transparent
		var flash_count = 0
		var max_flashes = int(invulnerability_duration * 4) # Flashes 4 times per second
		while flash_count < max_flashes and is_invulnerable:
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(1,1,1,0.3)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.material_override = material
			await get_tree().create_timer(0.125).timeout
			
			if is_instance_valid(mesh):
				mesh.material_override = null
				
			await get_tree().create_timer(0.125).timeout
			flash_count += 1
			
		if is_instance_valid(mesh):
			mesh.material_override = null
		
func rotate_character_to_cursor(direction: Vector3):
	if pivot and direction.length() > 0.1:
		# Calculates target rotation from direction
		var target_rotation = atan2(direction.x, direction.z)
		# Smoothes the rotation with lerp
		pivot.rotation.y = lerp_angle(pivot.rotation.y, target_rotation, rotation_speed * get_process_delta_time())
		
func die():
	print("Player died!")
	# TODO: Game over logic
	get_tree().reload_current_scene() # respawns whole room for now
	
func disable_input():
	set_process_input(false)
	set_process_unhandled_input(false)
