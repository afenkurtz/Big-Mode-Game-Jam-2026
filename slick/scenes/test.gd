extends Area3D

@export var heal_amount = 25.0
@export var rotate_speed = 2.0 # Rotation Speed for visual effect
@export var bob_height = 0.3 # How much it moves up and down
@export var bob_speed = 2.0 # Speed bobbing

var player_ref = null
var time_passed = 0.0
var initial_y = 0.0

func _process(delta):
	# ONLY attraction, nothing else
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("player")
	
	if player_ref:
		var distance = global_position.distance_to(player_ref.global_position)
		if distance < 3.0:
			var direction = (player_ref.global_position - global_position).normalized()
			global_position += direction * 5.0 * delta
