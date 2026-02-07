extends CanvasLayer

@onready var ammo_label = $HUDContainer/AmmoLabel
@onready var health_bar = $HUDContainer/HealthBar
@onready var cooldown_bar = $HUDContainer/CooldownBar
@onready var coin_label = $HUDContainer/CoinLabel
var player = null
var last_ammo = 0.0
var last_health = 0.0
var health_tween: Tween

func _ready():
	player = get_parent()
	
	# Set health bar max value
	if health_bar and player:
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health
	
	# Setup cooldown bar
	if cooldown_bar:
		cooldown_bar.max_value = 1.0
		cooldown_bar.value = 0.0
	
	update_hud()

func _process(delta):
	if player:
		# Update when values change
		if player.current_ammo != last_ammo or player.current_health != last_health:
			update_hud()
			last_ammo = player.current_ammo
			last_health = player.current_health
		
		# Always update cooldown (it changes every frame)
		update_cooldown()
		update_coins()

func update_hud():
	update_ammo()
	update_health()

func update_ammo():
	if player and ammo_label:
		ammo_label.text = "Ammo: " + str(int(player.current_ammo)) + "/" + str(int(player.max_ammo))
		

func update_health():
	if player and health_bar:
		if health_tween:
			health_tween.kill()
		
		health_tween = create_tween()
		health_tween.tween_property(
			health_bar,
			"value",
			player.current_health,
			0.3
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
func update_coins(): 
	print("update coins called")
	if player and coin_label:
		coin_label.text = "🪙 X " + str(player.coins_collected)

func update_cooldown():
	if player and cooldown_bar:
		# Calculate normalized cooldown (0 = ready, 1 = just attacked)
		var normalized_cooldown = 0.0
		
		if player.combo_timer > 0:
			# Show cooldown filling up as timer counts down
			normalized_cooldown = 1.0 - (player.combo_timer / player.combo_window)
		else:
			# Ready to attack
			normalized_cooldown = 1.0
		
		cooldown_bar.value = normalized_cooldown
		
