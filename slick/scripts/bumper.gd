extends Area3D

# Bounce Parameters
@export var bounce_force = 25.0
@export var bounce_upward = 5.0

# Bounce Sound
@export var bump_sound: AudioStream

@onready var audio_player = AudioStreamPlayer3D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Signals
	body_entered.connect(_on_body_entered)
	# Add to bumper group
	add_to_group("bumper")
	
	add_child(audio_player)
	if bump_sound:
		audio_player.stream = bump_sound
	
func _on_body_entered(body):
	print ("Bumper hit by: ", body.name)
	
	#checks if body that hits is enemy or player
	if body is CharacterBody3D:
		#calculate bounce direction (away from bumper center)
		var bounce_direction = (body.global_position - global_position).normalized()
		bounce_direction.y = 0
		
		# Apply force
		if "velocity" in body:
			body.velocity.x = bounce_direction.x * bounce_force
			body.velocity.z = bounce_direction.z * bounce_force
			
			print("Launched with force: ", bounce_force)
			
			# visual/audio feedback
			bump_effect()
			
func bump_effect():
	# Play Sound
	if audio_player and audio_player.stream:
		audio_player.play()
		#flash bumper when triggered
	var mesh = $MeshInstance3D
	
	if mesh:
		# Scale up, then back down
		var tween = create_tween()
		#scale up, flash white
		tween.set_parallel(true)
		tween.tween_property(mesh, "scale", Vector3( 1.3, 1.3, 1.3 ), 0.1 )
		tween.tween_property(self, "modulate", Color(2,2,2), 0.1)
		
		#scale down, reset mesh
		tween.chain()
		tween.set_parallel(true)
		tween.tween_property(mesh, "scale", Vector3( 1.0, 1.0, 1.0 ), 0.1 )
		tween.tween_property(self, "modulate", Color(1,1,1), 0.2)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
