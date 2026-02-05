extends Area3D

@export var boost_speed = 60.0 # Speed to set when boosting
@export var boost_direction = Vector3.FORWARD # direction to boost

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("boost_pad")
	
func _on_body_entered(body):
	print("Boost pad triggered by: ", body.name)
	
	#checks if it's the player
	if body.is_in_group("player") and body.has_method("apply_boost"):
		# get boost direction in world space
		var world_boost_direction = global_transform.basis * boost_direction
		world_boost_direction.y = 0
		world_boost_direction = world_boost_direction.normalized()
		
		# Apply boost to player
		body.apply_boost(world_boost_direction, boost_speed)
		
		# visual feedback
		#boost_effect()
		
#func boost_effect():
	# Flash and pusle when activated
	#var mesh = $MeshInstance3D
	#if mesh:
		#var tween = create_tween()
		#tween.set_parallel(true)
		#tween.tween_property(mesh, "scale", Vector3(1.2, 1.5, 1.2), 0.15)
		#tween.tween_property(self, "modulate", Color(2, 2, 3), 0.15)
		
		#tween.chain()
		#tween.set_parallel(true)
		#tween.tween_property(mesh, "scale", Vector3(3.0, 0.3, 3.0), 0.3)
		#tween.tween_property(self, "modulate", Color(1,1,1), 0.3)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
