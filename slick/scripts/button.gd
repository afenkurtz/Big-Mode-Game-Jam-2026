extends Area3D

signal button_pressed

@export var connected_gate: NodePath
@export var press_depth = 0.1
@export var press_speed = 10.0
@export var enable_color_feedback = true
@export var pressed_color = Color(0, 1, 0)
@export var unpressed_color = Color(1, 0, 0)
@export var permanent = false  # NEW - if true, button stays pressed forever

var is_pressed = false
var initial_position = Vector3.ZERO
var gate_node = null
var button_pad = null
var button_material: StandardMaterial3D

func _ready():
	button_pad = find_child("ButtonPad", true, false)
	if not button_pad:
		button_pad = get_child(1)
	
	if button_pad:
		initial_position = button_pad.position
	
	body_entered.connect(_on_body_entered)
	
	# Only connect body_exited if not permanent
	if not permanent:
		body_exited.connect(_on_body_exited)
	
	if connected_gate:
		gate_node = get_node(connected_gate)
	
	add_to_group("button")
	
	if enable_color_feedback:
		setup_button_color()

func setup_button_color():
	var mesh = find_mesh_instance(button_pad)
	
	if mesh:
		button_material = StandardMaterial3D.new()
		button_material.albedo_color = unpressed_color
		mesh.material_override = button_material
		print("Button color setup complete")
	else:
		print("Warning: Could not find MeshInstance3D for button color")

func find_mesh_instance(node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	
	for child in node.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
	
	return null

func _process(delta):
	if not button_pad:
		return
	
	var target_y = initial_position.y - press_depth if is_pressed else initial_position.y
	button_pad.position.y = lerp(button_pad.position.y, target_y, press_speed * delta)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_pressed:
		is_pressed = true
		print("Button activated!")
		button_pressed.emit()
		
		# Change color to pressed
		if enable_color_feedback and button_material:
			button_material.albedo_color = pressed_color
		
		# Notify gate
		if gate_node and gate_node.has_method("button_activated"):
			gate_node.button_activated()

func _on_body_exited(body):
	if body.is_in_group("player") and is_pressed:
		is_pressed = false
		print("Button deactivated!")
		
		# Change color to unpressed
		if enable_color_feedback and button_material:
			button_material.albedo_color = unpressed_color
		
		# Notify gate
		if gate_node and gate_node.has_method("button_deactivated"):
			gate_node.button_deactivated()
