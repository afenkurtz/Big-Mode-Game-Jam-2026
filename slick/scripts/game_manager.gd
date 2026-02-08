extends Node

var level_times = {}
var current_level_name = ""
var current_level_time = 0.0
var timer_running = false

#Total Stats
var total_coins = 0
var total_deaths = 0


func start_level(level_name: String):
	current_level_name = level_name
	current_level_time = 0.0
	timer_running = true
	print("Started timer for: ", level_name)
	
func stop_level():
	timer_running = false
	
	if current_level_name != "":
		level_times[current_level_name] = current_level_time
		print("Level complete! ", current_level_name, "time: ", format_time(current_level_time))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer_running:
		current_level_time += delta
	
func get_level_time(level_name: String) -> float:
	if level_name in level_times:
		return level_times[level_name]
	return 0.0
	
func get_total_time() -> float:
	var total = 0.0
	for time in level_times.values():
		total += time
	return total
	
func format_time(time: float) -> String:
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
	
func reset_all_stats():
	level_times.clear()
	current_level_time = 0.0
	timer_running = false
	total_coins = 0
	total_deaths = 0
	print("All stats reset")
	
