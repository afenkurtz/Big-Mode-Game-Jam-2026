extends Control

@onready var play_button = $MenuContainer/ButtonContainer/PlayButton
@onready var quit_button = $MenuContainer/ButtonContainer/QuitButton

var game_scene_path = "res://scenes/levels/level0.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set mouse mode to visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Button Signals
	
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
func _on_play_pressed():
	print("Starting game...")
	# Load game scene
	get_tree().change_scene_to_file(game_scene_path)


func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
