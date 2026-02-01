extends RigidBody3D

var velocity = Vector3.ZERO
var damage = 25.0
var lifetime = 5.0

func _ready():
	# Disable gravity for projectile
	gravity_scale = 0
	
	# IMPORTANT: Set continuous collision detection for fast-moving projectiles
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 5
	
	# Add projectile to group
	add_to_group("projectile")
	
	# Set collision properties
	collision_layer = 2
	collision_mask = 1
	
	print("=== PROJECTILE CREATED ===")
	print("Position: ", global_position)
	print("Velocity: ", velocity)
	print("Continuous CD: ", continuous_cd)
	print("Contact monitor: ", contact_monitor)
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	# Move projectile
	global_position += velocity * delta
	print("Projectile at: ", global_position)

func set_velocity(vel: Vector3):
	velocity = vel
	print("Projectile velocity set to: ", velocity)

func _on_body_entered(body):
	print("=== PROJECTILE HIT ===")
	print("Hit body: ", body.name)
	print("Body type: ", body.get_class())
	print("Is in enemy group: ", body.is_in_group("enemy"))
	print("Has take_damage: ", body.has_method("take_damage"))
	
	# Don't hit the player who shot it
	if body.is_in_group("player"):
		print("Hit player - ignoring")
		return
	
	# Check if it hit an enemy
	if body.is_in_group("enemy"):
		print("HIT ENEMY - Dealing damage!")
		if body.has_method("take_damage"):
			body.take_damage(damage)
	
	elif body.is_in_group("breakable"):
		print("Hit breakable!")
		if body.has_method("take_damage"):
			body.take_damage(damage)
	
	# Destroy projectile on any hit
	#print("Destroying projectile")
	queue_free()
