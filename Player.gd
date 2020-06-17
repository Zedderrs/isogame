extends KinematicBody2D

# scene components
onready var body_player = $BodyPlayer
onready var hair_player = $HairPlayer
onready var body_run = $BodyRun
onready var body_idle = $BodyIdle
onready var hair_run = $HairRun
onready var hair_idle = $HairIdle

# animation dictionary
var Body = {"Elf": "elf_body"}
var Hair = {"Elf": "elf_hair"}
var Action = {"Idle": "_idle", "Run": "_run"} 
var Dir = {"N":"_n", "NE":"_ne", "E":"_e", "SE":"_se", "S":"_s", "SW":"_sw", "W":"_w", "NW":"_nw"}
# scene constants
const SPEED = 250 # How fast the player will move (pixels/sec).

# player vars
var velocity
var player_body
var player_hair
var player_action
var player_direction
var current_player_action
var current_player_direction
# scene vars
var game
var screen_size
var current_body_animation

# ==============================================================================
# ------------------ Player Input and Movement Mechanics -----------------------
# ==============================================================================

func _ready():
	screen_size = OS.get_screen_size()
	game = get_tree().get_root().get_node("Game")
	
	# player animations
	player_body = Body.Elf
	player_hair = Hair.Elf
	# player state
	player_action = Action.Idle
	player_direction = Dir.S
	current_player_action = player_action
	current_player_direction = player_direction

func _input(event):
	# don't process echo events
	if (event.is_echo()): return
	
func _physics_process(_delta):
	# set the current animation to play
#	animation_player.play("elf_idle_e")
	
	# set the current velocity
	velocity = Vector2()  
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
		# move and slide player
		move_and_slide(velocity)
		# open the door if player collides with a door
		open_door()
		if previous_position.distance_squared_to(position) < 2:
			player_action = Action.Idle
		else:
			player_action = Action.Run
	else:
		player_action = Action.Idle
	
	player_direction = get_cardinal_direction(velocity.normalized())
	set_animations()

func set_animations():
	if animation_changed():
		print("animation changed: ", animation_changed())
		set_animations_visiblities() # show relevant sprites for animation
		play_animations()

func animation_changed(): # does the animation need to change?
	return player_action != current_player_action || player_direction != current_player_direction || "" == body_player.get_current_animation()
	
func set_animations_visiblities(): # set which sprites are visible to show animations
	body_run.visible = player_action == Action.Run
	hair_run.visible = player_action == Action.Run
	body_idle.visible = player_action == Action.Idle
	hair_idle.visible = player_action == Action.Idle

func play_animations():
	print("animation: ", player_body + player_action + player_direction)
	body_player.play(player_body + player_action + player_direction) # animate body
	hair_player.play(player_hair + player_action + player_direction) # animate hair
	current_player_action = player_action
	current_player_direction = player_direction

func get_cardinal_direction(p_dir_norm): # returns cardinal direction based on velocity vector
	if p_dir_norm.is_equal_approx(Vector2(0, -1)):
		return Dir.N
	elif p_dir_norm.x > 0 && p_dir_norm.y < 0:
		return Dir.NE
	elif p_dir_norm.is_equal_approx(Vector2(1, 0)):
		return Dir.E
	elif p_dir_norm.x > 0 && p_dir_norm.y > 0:
		return Dir.SE
	elif p_dir_norm.is_equal_approx(Vector2(0, 1)):
		return Dir.S
	elif p_dir_norm.x < 0 && p_dir_norm.y > 0:
		return Dir.SW
	elif p_dir_norm.is_equal_approx(Vector2(-1, 0)):
		return Dir.W
	elif p_dir_norm.x < 0 && p_dir_norm.y < 0:
		return Dir.NW
	elif p_dir_norm.is_equal_approx(Vector2(0, 0)):
		return current_player_direction

func open_door(): # opens the door if player collides with it
		for i in get_slide_count():
			var collider = get_slide_collision(i).collider
			if game.is_door_closed(game.get_instance_type(collider)):
				var map_coords = game.map.world_to_map(Vector2(collider.position.x, collider.position.y))
				game.set_door_tile(map_coords.x, map_coords.y, true)
