extends Area3D

@export var coin_value = 1  # How many coins this is worth
@export var rotate_speed = 3.0
@export var bob_height = 0.2
@export var bob_speed = 2.0
@export var collect_sound: AudioStream

var phase_offset = 0.0
var time_passed = 0.0
var initial_position = Vector3.ZERO

func _ready():
	initial_position = global_position
	body_entered.connect(_on_body_entered)
	phase_offset = (global_position.x * 0.5 ) + (global_position.y * 0.3)
	add_to_group("coin")

func _process(delta):
	time_passed += delta
	
	# Rotate coin
	rotation.y += rotate_speed * delta
	
	# Bob up and down
	var new_y = initial_position.y + sin((time_passed * bob_speed) + phase_offset) * bob_height
	global_position.y = new_y

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect(body)

func collect(player):
	print("Coin collected!")
	
		# Play sound
	if collect_sound:
		var audio = AudioStreamPlayer3D.new()
		get_parent().add_child(audio)
		audio.stream = collect_sound
		audio.global_position = global_position
		audio.play()
		
		# Cleanup after sound finishes
		await audio.finished
		audio.queue_free()
	
	# Add coin to player
	if player.has_method("add_coins"):
		player.add_coins(coin_value)
	
	# Particle effect
	spawn_collect_particles()
	
	# Remove coin
	queue_free()

func spawn_collect_particles():
	var particles = CPUParticles3D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.05
	particles.mesh = sphere_mesh
	
	# Emission
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.3
	
	# Movement
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 4.0
	particles.gravity = Vector3(0, -5.0, 0)
	
	# Appearance
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.5
	particles.color = Color(1.0, 0.8, 0.0)  # Gold
	
	# Settings
	particles.amount = 10
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true
	
	# Cleanup
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()
		
