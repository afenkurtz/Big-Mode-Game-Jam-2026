extends CharacterBody3D

@onready var pivot = $Pivot

var animation_tree: AnimationTree

@export var chase_force = 50 # how quickly the enemy will move toward the player
@export var friction_coefficient = 0.99
@export var ground_friction = 0.96
@export var max_speed = 35.0
@export var chase_distance = 50.0
@export var attack_range = 2.0

#health
@export var max_health = 100.0
var current_health = max_health

# Attack Parameters
@export var attack_damage = 15.0
@export var attack_cooldown = 1.5
@export var knockback_strength = 30.0
var attack_timer = 0.0

# Stun system
@export var stun_duration = 0.8  # How long enemies are stunned
var is_stunned = false
var stun_timer = 0.0

#physics - gravity (uses godot defaults)
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#player reference - used to allow the enemy to chase the players position
var player: CharacterBody3D = null

func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")
	
	# Debug collision setup
	print("=== ENEMY SETUP ===")
	print("Enemy name: ", name)
	print("Enemy position: ", global_position)
	print("Collision layer: ", collision_layer)
	print("Collision mask: ", collision_mask)
	
	if has_node("CollisionShape3D"):
		var col_shape = $CollisionShape3D
		print("Has collision shape: YES")
		print("Shape type: ", col_shape.shape)
		print("Shape disabled: ", col_shape.disabled)
	else:
		print("ERROR: NO COLLISION SHAPE FOUND!")
	print("===================")
	
	animation_tree = $AnimationTree
	animation_tree.connect("animation_finished", _on_animation_finished)
	
func _on_animation_finished(anim_name: String):
	if anim_name in ["get_hit", "hit", "run"]:
		animation_tree["parameters/playback"].travel("idle")
		
func play_animation(anim_name: String):
	animation_tree["parameters/playback"].travel(anim_name)
		
func _physics_process(delta):
	# update stun timer
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			print("Stun ended")
			var mesh = $MeshInstance3D
			if mesh:
				mesh.material_override = null
	
	# Update attack cooldown
	if attack_timer > 0:
		attack_timer -= delta

	#apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
# Try to find player
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			move_and_slide()
			return
	
	# Skip AI if stunned
	if is_stunned:
		if is_on_floor():
			velocity.x *= friction_coefficient * ground_friction
			velocity.z *= friction_coefficient * ground_friction
		else:
			velocity.x *= friction_coefficient
			velocity.z *= friction_coefficient
		
		move_and_slide()
		return
	
	#checks if player is in range, if player is in range, chase player
	if player != null:
		play_animation("run")
		
		var distance_to_player = global_position.distance_to(player.global_position)
		#print("Distance: ", distance_to_player, " | Chase distance: ", chase_distance, " | Attack range: ", attack_range)
		if distance_to_player < chase_distance and distance_to_player > attack_range:
			# Predict where player will be
			var time_to_reach = distance_to_player / max_speed
			var predicted_position = player.global_position + player.velocity * time_to_reach * 0.5
	
			# Calculate direction to predicted position
			var direction = (predicted_position - global_position).normalized()
			direction.y = 0
			
			# Rotate to face player
			var target_rotation = atan2(direction.x, direction.z)
			pivot.rotation.y = lerp_angle(pivot.rotation.y, target_rotation, 10.0 * delta)
	
			velocity.x += direction.x * chase_force * delta
			velocity.z += direction.z * chase_force * delta
			
			#print("velocity: ", velocity)
			
			
		elif distance_to_player <= attack_range:
			if attack_timer <= 0:
				perform_melee_attack()
				attack_timer = attack_cooldown
			
	if is_on_floor():
		velocity.x *= friction_coefficient * ground_friction
		velocity.z *= friction_coefficient * ground_friction
	else:
		velocity.x *= friction_coefficient
		velocity.z *= friction_coefficient
			
		#cap maximum speed
		var horizontal_velocity = Vector2(velocity.x, velocity.z)
		if horizontal_velocity.length() > max_speed:
			horizontal_velocity = horizontal_velocity.normalized() * max_speed
			velocity.x = horizontal_velocity.x
			velocity.z = horizontal_velocity.y
			
	# Move the character

	move_and_slide()

		
func take_damage(amount: float, attacker_position: Vector3 = Vector3.ZERO):
	$HitSound.play()
	play_animation("get_hit")
	
	current_health -= amount
	print("Enemy took ", amount, " damage, Health: ", current_health)
	
	#Apply knockback if attacker position provided
	if attacker_position != Vector3.ZERO:
		var knockback_dir = (global_position - attacker_position).normalized()
		knockback_dir.y = 0
		
		# Apply knockback force to velocity
		velocity.x += knockback_dir.x * knockback_strength
		velocity.z += knockback_dir.z * knockback_strength
		
		# Apply stun
		apply_stun()
	
	#visual feedback for hit
	flash_red()
		
	if current_health <= 0:
		die()
	
func apply_stun():
	is_stunned = true
	stun_timer = stun_duration
	
	# Visual feedback
	var mesh = $Pivot/Enemy_Rat_2/Armature_001/Skeleton3D/Rat_001
	if mesh:
		var stun_material = StandardMaterial3D.new()
		stun_material.albedo_color = Color(0.5, 0.5, 0.5)
		mesh.material_override = stun_material
	
	# Spawn stun stars
	spawn_stun_stars()

func spawn_stun_stars():
	# Create circling stars above enemy
	for i in range(3):
		var star = MeshInstance3D.new()
		add_child(star)
		
		var star_mesh = SphereMesh.new()
		star_mesh.radius = 0.2
		star.mesh = star_mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 1, 0)
		material.emission_enabled = true
		material.emission = Color(1, 1, 0)
		star.material_override = material
		
		# Position above head
		star.position = Vector3(0, 2, 0)
		
		# Animate circling
		var tween = create_tween()
		tween.set_loops(int(stun_duration * 2))
		tween.tween_property(star, "rotation:y", TAU, 0.5)
		
		# Cleanup
		get_tree().create_timer(stun_duration).timeout.connect(
			func(): 
				if is_instance_valid(star):
					star.queue_free()
		)
	
func perform_melee_attack():
	print("Enemy melee attack")
	
	#Check if the player is still in range
	if player !=null and global_position.distance_to(player.global_position) <= attack_range:
		$AttackSound.play()
		play_animation("hit")
		
		# Damage the player
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, global_position)
			print("Hit player for ", attack_damage, " damage!")
	
func flash_red():
	var mesh = $Pivot/Enemy_Rat_2/Armature_001/Skeleton3D/Rat_001
	if mesh:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.RED
		mesh.material_override = material
		
	#reset mesh color after delay
	await get_tree().create_timer(0.1).timeout
	mesh.material_override = null
	
func die():
	$DieSound.play()
	play_animation("die")
	
	print("Enemy died!")
	queue_free()
		
