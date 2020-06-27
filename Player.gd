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
var space_graph
var screen_size
var current_body_animation
var target

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
	velocity = Vector2()

func _input(event):
	if event.is_action_released("left_click"):
		target = get_global_mouse_position()
	
func _physics_process(_delta):
	if Input.is_mouse_button_pressed(1):
		target = get_global_mouse_position()
	move_to_target()
	direction = get_cardinal_direction(velocity)
	set_animations()

func move_to_target():
	if !target: target = position
	velocity = (target - position).normalized() * SPEED
	if (target - position).length() > 5:
		var previous_position = position
		velocity = move_and_slide(velocity)
		open_door() # open the door if player collides with a door
		if previous_position.distance_squared_to(position) < 2:
			if hit():
				action = Action.Attack
			else:
				action = Action.Idle
		else:
			action = Action.Run
	else:
		action = Action.Idle

func set_animations():
	if change_animation():
		play_animations()

func change_animation(): # can the animation be changed?
	var action_changed = action != current_action
	var direction_changed = direction != current_direction
	var no_animation_playing = "" == body_animation_player.get_current_animation()
	if is_attacking(): return false
	return action_changed || direction_changed || no_animation_playing

	
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

func get_cardinal_direction(dir): # returns cardinal direction based on velocity vector
	var dir_n = dir.normalized()
	var x = dir_n.x
	var y = -dir_n.y
	if x >= cos(deg2rad(22.5)) && y >= sin(deg2rad(-22.5)) && y <= sin(deg2rad(22.5)): return Dir.E
	elif x >= cos(deg2rad(67.5)) && x <= cos(deg2rad(22.5)) && y >= sin(deg2rad(22.5)) && y <= sin(deg2rad(67.5)): return Dir.NE
	elif x >= cos(deg2rad(112.5)) && x <= cos(deg2rad(67.5)) && y >= sin(deg2rad(67.5)): return Dir.N
	elif x >= cos(deg2rad(157.5)) && x <= cos(deg2rad(112.5)) && y >= sin(deg2rad(157.5)) && y <= sin(deg2rad(112.5)): return Dir.NW
	elif x <= cos(deg2rad(157.5)) && y >= sin(deg2rad(202.5)) && y <= sin(deg2rad(157.5)): return Dir.W
	elif x >= cos(deg2rad(202.5)) && x <= cos(deg2rad(247.5)) && y >= sin(deg2rad(247.5)) && y <= sin(deg2rad(202.5)): return Dir.SW
	elif x >= cos(deg2rad(247.5)) && x <= cos(deg2rad(292.5)) && y <= sin(deg2rad(292.5)): return Dir.S
	elif x >= cos(deg2rad(292.5)) && x <= cos(deg2rad(337.5)) && y >= sin(deg2rad(292.5)) && y <= sin(deg2rad(337.5)): return Dir.SE
	else: return current_direction

func open_door(): # opens the door if player collides with it
	for i in get_slide_count():
		var collider = get_slide_collision(i).collider
		if game.is_door_closed(game.get_instance_type(collider)):
			var map_coords = game.map.world_to_map(Vector2(collider.position.x, collider.position.y))
			game.set_door_tile(map_coords.x, map_coords.y, true)

func is_attacking():
	return -1 != body_animation_player.get_current_animation().find("1h_attack")

func hit():
	for i in get_slide_count():
		var collider = get_slide_collision(i).collider
		for enemy in game.enemies:
			if enemy.get_instance_id() == collider.get_instance_id():
				attack(enemy)
				return true
		return false

func attack(enemy):
	enemy.take_damage(1)

func _on_WeaponCollision_body_entered(collider):
	#print("area entered: ", collider.get_instance_id(), " body type found: ", game.get_instance_type(collider))
	if game.is_breakable_object(game.get_instance_type(collider)):
		game.hurt(game.get_object_by_id(collider.get_instance_id()))

func is_empty_tile(tile):
	return tile != game.Tile.Block && !game.is_wall(tile) && (game.is_door(tile) && !game.is_closed_door(tile))
