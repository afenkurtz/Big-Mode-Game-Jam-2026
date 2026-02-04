extends CanvasLayer

@onready var resume_button = $MenuContainer/ButtonContainer/ResumeButton
@onready var restart_button = $MenuContainer/ButtonContainer/RestartButton
@onready var quit_button = $MenuContainer/ButtonContainer/QuitButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#hides the menu when opening game.
	visible = false

	#Button Signals
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
func _input(event):
	#Toggle pause with ESC key
	if event.is_action_pressed("ui_cancel"): #ESC key by default
		toggle_pause()
		
func toggle_pause():
	visible = !visible
	#Pause/Unpause the game
	get_tree().paused = visible
	
	#Release mouse if paused (makes the buttons clickable
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
func _on_resume_pressed():
	toggle_pause()
	
func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
	
func _on_quit_pressed():
	#Unpause before quitting
	get_tree().paused = false
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
