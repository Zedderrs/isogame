extends KinematicBody2D

# animation nodes
onready var body_animation_player = $BodySprite/BodyAnimationPlayer
onready var hair_animation_player = $HairSprite/HairAnimationPlayer
onready var top_animation_player = $TopSprite/TopAnimationPlayer
onready var bottom_animation_player = $BottomSprite/BottomAnimationPlayer
onready var weapon_animation_player = $WeaponSprite/WeaponAnimationPlayer
onready var slash_animation_player = $SlashSprite/SlashAnimationPlayer

# animation dictionary
var Gender = {"Male": "male_"}
var Body = {"Elf": "elf_body"}
var Top = {"Elf": "elf_top"}
var Hair = {"Elf": "elf_hair"}
var Bottom = {"Elf": "elf_bottom"}
var Weapon = {"Sword": "weapon_sword"}
var Action = {"Idle": "_idle", "Run": "_run", "Attack": "_1h_attack"} 
var Dir = {"N":"_n", "NE":"_ne", "E":"_e", "SE":"_se", "S":"_s", "SW":"_sw", "W":"_w", "NW":"_nw"}

# scene constants
const SPEED = 250 # How fast the player will move (pixels/sec).

# player state vars
var velocity
var gender
var body
var hair
var top
var bottom
var weapon
var action
var direction
var current_action
var current_direction

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
	gender = Gender.Male
	body = Body.Elf
	hair = Hair.Elf
	top = Top.Elf
	bottom = Bottom.Elf
	weapon = Weapon.Sword
	# player state
	action = Action.Idle
	direction = Dir.S
	current_action = action
	current_direction = direction

func _physics_process(_delta):
	# set the current velocity
	velocity = Vector2()  
	if Input.is_action_pressed("right"):
		velocity.x += 1
	if Input.is_action_pressed("left"):
		velocity.x -= 1
	if Input.is_action_pressed("down"):
		velocity.y += 0.5
	if Input.is_action_pressed("up"):
		velocity.y -= 0.5
	if Input.is_action_pressed("attack"):
		action = Action.Attack
		velocity = Vector2(0, 0)
	elif velocity.length() > 0:
		var previous_position = position
		velocity = velocity.normalized() * SPEED
		# warning-ignore:return_value_discarded
		if !is_attacking(): 
			move_and_slide(velocity) # move and slide player
			open_door() # open the door if player collides with a door
			if previous_position.distance_squared_to(position) < 2:
				action = Action.Idle
			else:
				action = Action.Run
	else:
		action = Action.Idle

	direction = get_cardinal_direction(velocity.normalized())
	set_animations()

func set_animations():
	if change_animation():
		play_animations()

func change_animation(): # can the animation be changed?
	var action_changed = action != current_action
	var direction_changed = direction != current_direction
	var no_animation_playing = "" == body_animation_player.get_current_animation()
	if is_attacking(): return false
	return action_changed || direction_changed || no_animation_playing

func is_attacking():
	return -1 != body_animation_player.get_current_animation().find("1h_attack")
	
func play_animations():
	body_animation_player.play(gender + body + action + direction) # animate body
	hair_animation_player.play(gender + hair + action + direction) # animate hair
	top_animation_player.play(gender + top + action + direction) # animate top
	bottom_animation_player.play(gender + bottom + action + direction) # animate bottom
	weapon_animation_player.play(gender + weapon + action + direction) # animate weapon
	
	if is_attacking() && direction == Dir.S:
		$SlashSprite.visible = true 
		slash_animation_player.play("slash_s")
	else:
		$SlashSprite.visible = false
	# update action and direction
	current_action = action
	current_direction = direction

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
		return current_direction

func open_door(): # opens the door if player collides with it
	for i in get_slide_count():
		var collider = get_slide_collision(i).collider
		if game.is_door_closed(game.get_instance_type(collider)):
			var map_coords = game.map.world_to_map(Vector2(collider.position.x, collider.position.y))
			game.set_door_tile(map_coords.x, map_coords.y, true)

func _on_WeaponCollision_body_entered(collider):
	print("area entered: ", collider.get_instance_id(), " body type found: ", game.get_instance_type(collider))
	if game.is_breakable_object(game.get_instance_type(collider)):
		game.hurt(game.get_object_by_id(collider.get_instance_id()))
