extends KinematicBody2D

# scene components
onready var player = $PlayerSprite

# scene constants
const SPEED = 250 # How fast the player will move (pixels/sec).

# scene vars
var game
var pressed_keys
var screen_size
var map_tile
var player_direction

# ==============================================================================
# ------------------------- Pressed Key State Class ----------------------------
# ==============================================================================

# PressedKeys state determines the player animation
class PressedKeys:
	var up = false
	var down = false
	var left = false
	var right = false
	
	var num_keys_pressed = 0
	var last_released
	
	# update number of directional keys currently pressed 
	func dir_keys_pressed(pressed):
		if pressed: num_keys_pressed += 1
		else: num_keys_pressed -= 1
		
	# update key pressed state
	func update_key_pressed(event, pressed):
		# update key pressed state and update release state
		if event.is_action("ui_up"):
			up = pressed
			update_directional_keys_state("up", pressed)
		elif event.is_action("ui_down"):
			down = pressed
			update_directional_keys_state("down", pressed)
		elif event.is_action("ui_left"):
			left = pressed
			update_directional_keys_state("left", pressed)
		elif event.is_action("ui_right"):
			right = pressed
			update_directional_keys_state("right", pressed)
	
	# update number of keys pressed. 
	# update last key released state string. clear this if a key is pressed
	func update_directional_keys_state(key_string, pressed):
		dir_keys_pressed(pressed)
		if pressed:
			last_released = null
		else:
			if num_keys_pressed < 3: # don't consider if more than 2 keys are pressed
				if last_released == null:
					last_released = key_string
				else:
					last_released += key_string

	# get key state
	func set_animation(player):
		if up && !down && !left && !right:
			player.animation = "run_up"
		elif !up && down && !left && !right:
			player.animation = "run_down"
		elif !up && !down && left && !right:
			player.animation = "run_left"
		elif !up && !down && !left && right:
			player.animation = "run_right"
		elif up && !down && left && !right:
			player.animation = "run_up_left"
		elif up && !down && !left && right:
			player.animation = "run_up_right"
		elif !up && down && left && !right:
			player.animation = "run_down_left"
		elif !up && down && !left && right:
			player.animation = "run_down_right"
		elif !up && !down && !left && !right:
			if last_released == "up":
				player.animation = "idle_up"
			elif last_released == "down":
				player.animation = "idle_down"
			elif last_released == "left":
				player.animation = "idle_left"
			elif last_released == "right":
				player.animation = "idle_right"
			elif last_released == "upright" || last_released == "rightup":
				player.animation = "idle_up_right"
			elif last_released == "upleft" || last_released == "leftup":
				player.animation = "idle_up_left"
			elif last_released == "downright" || last_released == "rightdown":
				player.animation = "idle_down_right"
			elif last_released == "downright" || last_released == "rightdown":
				player.animation = "idle_down_right"
			elif last_released == "downleft" || last_released == "leftdown":
				player.animation = "idle_down_left"
			else:
				player.animation = player.animation.replace("run","idle")

# ==============================================================================
# ------------------ Player Input and Movement Mechanics -----------------------
# ==============================================================================

func _ready():
	pressed_keys = PressedKeys.new()
	screen_size = OS.get_screen_size()
	game = get_tree().get_root().get_node("Game")

func _input(event):
	
	# don't process echo events
	if (event.is_echo()): return
	
	# update pressed key state
	pressed_keys.update_key_pressed(event, event.is_pressed())
	# update animation based on current key state
	pressed_keys.set_animation(player)
	
func _physics_process(_delta):
	var velocity = Vector2()  # The player's movement vector.
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 0.5
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 0.5

	if velocity.length() > 0:
		var previous_position = position
		velocity = velocity.normalized() * SPEED
		
		# move and save player's direction
		player_direction = move_and_slide(velocity)
		
		# change player's animation to idle if last movement didn't change the position much
		if previous_position.distance_squared_to(position) < 2:
			player.animation = player.animation.replace("run","idle")
		
		# get player's current collision info
		for i in get_slide_count():
			var collider = get_slide_collision(i).collider
			if game.is_door_closed(game.get_instance_type(collider)):
				var map_coords = game.map.world_to_map(Vector2(collider.position.x, collider.position.y))
				game.set_door_tile(map_coords.x, map_coords.y, true)
