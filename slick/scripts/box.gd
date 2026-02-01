extends StaticBody3D

@export var max_health = 50.0
@export var drop_debris = true
@export var debris_pieces = 5

var current_health = max_health

func _ready():
	current_health = max_health
	# Add to breakable group so attacks can find it
	add_to_group("breakable")
	
	print("Breakable object created with ", max_health, " health")

func take_damage(amount: float):
	current_health -= amount
	print("Breakable took ", amount, " damage. Health: ", current_health)
	
	# Visual feedback - flash white
	flash_damage()
	
	if current_health <= 0:
		break_apart()

func flash_damage():
	var mesh = $MeshInstance3D
	if mesh:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.WHITE
		mesh.material_override = material
		
		await get_tree().create_timer(0.1).timeout
		if mesh and is_instance_valid(self):
			mesh.material_override = null

func break_apart():
	print("Object breaking!")
	
	# Spawn debris pieces
	if drop_debris:
		spawn_debris()
	
	# Optional: spawn loot, play sound, particle effects here
	
	# Remove the object
	queue_free()

func spawn_debris():
	# Create small debris pieces that fly outward
	for i in range(debris_pieces):
		var debris = RigidBody3D.new()
		get_parent().add_child(debris)
		# Position at broken object location
		debris.global_position = global_position
		
		# Add collision shape
		var col_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(0.3, 0.3, 0.3)  # Small pieces
		#col_shape.shape = box_shape
		debris.add_child(col_shape)
		
		# Add visual mesh
		var mesh_instance = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.3, 0.3, 0.3)
		mesh_instance.mesh = box_mesh
		debris.add_child(mesh_instance)
		
		# Random brown/tan color for wood-like debris
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(randf_range(0.4, 0.6), randf_range(0.3, 0.4), randf_range(0.2, 0.3))
		mesh_instance.material_override = material
		
		# Apply random outward force
		var random_direction = Vector3(
			randf_range(-1, 1),
			randf_range(0.5, 1.5),  # Mostly upward
			randf_range(-1, 1)
		).normalized()
		
		debris.linear_velocity = random_direction * randf_range(3, 8)
		debris.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
		
		get_tree().create_timer(3.0).timeout.connect(
			func():
				if is_instance_valid(debris):
					debris.queue_free()
					print("debris queue free!")
		)
		
		# Auto-cleanup debris after a few seconds --- ERROR: this doesnt work because it is created in the spawn debris function, which finishes running before the await, which waits to run its code until X signal is emitted
		#await get_tree().create_timer(3.0).timeout
		#if is_instance_valid(debris):
			#debris.queue_free()
			#print("debris cleared")
