extends Area3D

@export var heal_amount = 25.0
@export var rotate_speed = 2.0 # Rotation Speed for visual effect
@export var bob_height = 0.3 # How much it moves up and down
@export var bob_speed = 2.0 # Speed bobbing


var player_ref = null
var time_passed = 0.0
var initial_y = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Stores initial position
	initial_y = global_position.y
	# Connect pickup signal
	body_entered.connect(_on_body_entered)
	
	# add to group
	add_to_group("pickup")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_passed += delta
	# Always rotate and bob
	rotation.y += rotate_speed * delta
	var new_y = initial_y + sin(time_passed * bob_speed) * bob_height
	
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("player")
		#print("Health_pickup.gd: Player found")
	#check distance to player
	if player_ref:
		var distance = global_position.distance_to(player_ref.global_position)
		#print("distance to player: ", distance)
		
		if distance < 3.0: # Attract within 3 units
			print("attracting to player")
			# Move toward player
			var target_pos = player_ref.global_position + Vector3(0, 0.5, 0)
			global_position = global_position.lerp(target_pos, 20.0 * delta)
				
func _on_body_entered(body):
	print("Pickup touched by: ", body.name)
	# Check if it is the player
	if body.is_in_group("player"):
		#heal the player
		if body.has_method("heal"):
			var actual_heal = body.heal(heal_amount)
			print("Healed player for ", actual_heal," HP")
			#pickup effect
			pickup_effect(body)
			#remove pickup
			queue_free()

func pickup_effect(player):
	# Spawn particles
	var particles = CPUParticles3D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Visual mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	particles.mesh = sphere_mesh
	
	# Emission
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.3
	
	# Movement - fly upward
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 45.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 4.0
	particles.gravity = Vector3(0, -2.0, 0)
	
	# Appearance
	particles.scale_amount_min = 0.2
	particles.scale_amount_max = 0.4
	particles.color = Color(0, 1, 0)  # Green health particles
	
	# Settings
	particles.amount = 15
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true
	
	# Auto-cleanup
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()
