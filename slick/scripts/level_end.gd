extends Area3D

@export var complete_sound: AudioStream

@export_file ("*.tscn") var next_level_path: String = ""
@export var fade_duration = 1.0
@export var delay_before_fade = 0.5

var is_transitioning = false
var fade_overlay:ColorRect
var fade_canvas: CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	#create fade overlay
	create_fade_overlay()
	
	add_to_group("level_end")
	create_exit_particles()
	
func create_exit_particles():
	var particles = CPUParticles3D.new()
	add_child(particles)
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	particles.mesh = sphere_mesh
	
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(1, 2, 1)
	
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 20.0
	particles.gravity = Vector3(0, -2, 0)
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 2.0
	
	particles.color = Color(0, 1, 1)  # Cyan
	particles.amount = 30
	particles.lifetime = 2.0
	particles.emitting = true
	
func create_fade_overlay():
	#Creates a canvas layer that fades out
	fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 100 # Render on top
	add_child(fade_canvas)
	
	#Create black overlay
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0,0,0,0) #transparent
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.size = Vector2(1920,1080) # Fallback
	
	fade_canvas.add_child(fade_overlay)
	
	print("Fade overlay created: ", fade_overlay)
	print("Initial color: ", fade_overlay.color)
	
func _on_body_entered(body):
	if body.is_in_group("player") and not is_transitioning:
		trigger_level_end()
		
func trigger_level_end():
	is_transitioning = true
	print("Level complete")
	
	if complete_sound:
		var audio = AudioStreamPlayer.new()
		add_child(audio)
		audio.stream = complete_sound
		audio.play()
	
		# Disable player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var camera = player.get_node_or_null("Camera3D")
		if camera:
			camera.reparent(self)
			print("camera disabled")
		
	
	# Wait before fade
	print("Waiting ", delay_before_fade, " seconds...")
	await get_tree().create_timer(delay_before_fade).timeout
	print("Starting fade...")
	
	# Fade to black
	await fade_to_black()
	print("Fade complete!")
	
	# Load next level
	load_next_level()

func fade_to_black():
	if not fade_overlay:
		print("ERROR: fade_overlay is null!")
		return
	
	print("Fading from alpha ", fade_overlay.color.a, " to 1.0")
	
	# Create tween
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	
	print("Tween created, waiting for finish...")
	await tween.finished
	print("Tween finished! Final alpha: ", fade_overlay.color.a)

func load_next_level():
	print("Loading next level...")
	
	if next_level_path == "":
		print("No next level path set! Reloading current scene...")
		get_tree().reload_current_scene()
	else:
		print("Loading: ", next_level_path)
		var error = get_tree().change_scene_to_file(next_level_path)
		if error != OK:
			print("ERROR loading scene: ", error)
