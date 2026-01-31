extends RigidBody3D

@export var velocity = Vector3.ZERO
@export var damage = 10.0
@export var lifetime = 5.0

func _ready():
	# Disable gravity for projectile
	gravity_scale = 0
	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# Move projectile
	global_position += velocity * delta

func set_velocity(vel: Vector3):
	velocity = vel

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()  # Destroy on hit
