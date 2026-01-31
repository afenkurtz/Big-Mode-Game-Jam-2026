extends CharacterBody3D

# Movement parameters
@export var burst_force = 20.0
@export var friction_coefficient = .98
@export var ground_friction = 1
@export var max_speed = 30.0

#attack parameters
@export var stab_range = 3.0
@export var stab_damage = 25.0
@export var projectile_speed = 40.0
@export var projectile_scene: PackedScene #assign in inspector

# Physics
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Camera reference
@onready var camera = $Camera3D

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta/2
	
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
	print ("Stab attack in Direction: ", direction)
	
	#raycast forward to detect enemy
	var space_state = get_world_3d().direct_space_state
	var stab_start = global_position + Vector3 (0,1,0) # stabs at chest height
	var stab_end = stab_start + direction * stab_range 

	var query = PhysicsRayQueryParameters3D.create(stab_start, stab_end)
	query.exclude = [self]
	var hit = space_state.intersect_ray(query)
	
	if hit:
		print("Stab hit: ", hit.collider.name)
		#check if hit object has a take_damage method
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(stab_damage)
		#this is where we spawn a stab effect
		
func fire_projectile(direction: Vector3):
	print ("Firing projectile in direction: ", direction)
	print ("Player position: ", global_position)
	
	if projectile_scene == null:
		print("Warning: No projectile scene assigned!")
		return
		
	#spawn projectile
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	
	#position projectile between player and mouse target
	#var spawn_pos = global_position.lerp(target_pos, 0.2)
	#spawn_pos.y = global_position.y +1
	#projectile.global_position = spawn_pos
	
	
	#positions the projectile in front of the player
	var spawn_offset = direction * 2.0
	projectile.global_position = global_position + Vector3(0,1,0) + spawn_offset 
	
	#set projectile velocity (assumes projectile has a script with velocity property)
	if projectile.has_method("set_velocity"):
		projectile.set_velocity(direction * projectile_speed)
	elif "velocity" in projectile:
		projectile.velocity = direction * projectile_speed
	
func _ready():
	print("Player initialized with mouse control")
