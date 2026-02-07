extends AnimatableBody3D

@export var lowered_offset = Vector3(0, -5, 0)
@export var movement_speed = 2.0
@export var start_closed = true
@export var required_buttons = 1  # How many buttons must be pressed

var initial_position = Vector3.ZERO
var target_position = Vector3.ZERO
var is_open = false
var pressed_buttons = 0  # Track how many buttons are currently pressed

func _ready():
	initial_position = position
	
	if start_closed:
		target_position = initial_position
		is_open = false
	else:
		target_position = initial_position + lowered_offset
		position = target_position
		is_open = true
	
	add_to_group("gate")

func _physics_process(delta):
	position = position.lerp(target_position, movement_speed * delta)

func button_activated():
	pressed_buttons += 1
	print("Button pressed! (", pressed_buttons, "/", required_buttons, ")")
	
	# Open gate only when ALL required buttons are pressed
	if pressed_buttons >= required_buttons and not is_open:
		open_gate()

func button_deactivated():
	pressed_buttons -= 1
	print("Button released! (", pressed_buttons, "/", required_buttons, ")")
	
	# Close gate if any button is released
	if pressed_buttons < required_buttons and is_open:
		close_gate()

func open_gate():
	if not is_open:
		is_open = true
		target_position = initial_position + lowered_offset
		print("ALL BUTTONS PRESSED - Gate opening!")

func close_gate():
	if is_open:
		is_open = false
		target_position = initial_position
		print("Gate closing...")
