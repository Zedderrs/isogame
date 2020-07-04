extends KinematicBody2D

# animation nodes
onready var body_animation_player = $BodySprite/BodyAnimationPlayer
onready var hair_animation_player = $HairSprite/HairAnimationPlayer
onready var top_animation_player = $TopSprite/TopAnimationPlayer
onready var bottom_animation_player = $BottomSprite/BottomAnimationPlayer
onready var weapon_animation_player = $WeaponSprite/WeaponAnimationPlayer
onready var slash_animation_player = $SlashSprite/SlashAnimationPlayer
onready var raycast = $RayCast2D
onready var raycast_path = $PathRayCast2D

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
var avoidance_force
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

# player attributes
var attack_range

# scene vars
var game
var space_graph
var screen_size
var current_body_animation
var target
var interrupt_attack
var destination
var path

# steering
var avoidance_weight
var velocity_weight

# debug tools
var from_pt
var to_pt

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
	attack_range = 100
	# player movement
	path = []
	velocity = Vector2()
	destination = position

func _input(event):
	if event.is_action_pressed("left_click"):
		destination = get_global_mouse_position()
		if is_hovering_over_ground():
			update_navigation_path(position, get_global_mouse_position())
		if target && 0 == Input.get_current_cursor_shape(): # clear target if clicked to move
			target = null
			interrupt_attack = true
	
func _physics_process(delta):
	if Input.is_mouse_button_pressed(1): # while mouse left click is held down, update the destination
		destination = get_global_mouse_position()
		if is_hovering_over_ground():
			update_navigation_path(position, get_global_mouse_position())
	act(delta)
	direction = get_cardinal_direction(velocity)
	set_animations()
	
	if game.debug_mode:
		update() #draw debug
	
func act(delta):
	raycast.set_cast_to(destination-position)
	if can_attack():
		action = Action.Attack
	elif !at_destination() && !is_attacking():
		var previous_position = position
		if Input.is_mouse_button_pressed(1):
			move_direct()
		else:
			if is_clear_path():
				move_direct()
			else:
				move_along_path(delta * SPEED)
				
		open_door() # open the door if player collides with a door
		if previous_position.distance_squared_to(position) < 2:
			action = Action.Idle
		else:
			action = Action.Run
	else:
		action = Action.Idle

func is_clear_path():
	raycast.set_cast_to(destination-position)
	return !raycast.is_colliding()

func is_hovering_over_ground():
	var tile = game.map.world_to_map(get_global_mouse_position())
	return game.is_walkable_tile(game.tile_map[tile.x][tile.y])

func can_attack(): 
	# can attack if not already attacking, target exists, and target is within range
	return !is_attacking() && null != target && (target.position - position).length() <= attack_range

func at_destination():
	return (destination - position).length() < 5

func set_animations():
	if change_animation():
		play_animations()

func change_animation(): # can the animation be changed?
	if is_attacking(): return false
	var action_changed = action != current_action
	var direction_changed = direction != current_direction
	var no_animation_playing = "" == body_animation_player.get_current_animation()
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
	if interrupt_attack:
		return false
	return -1 != body_animation_player.get_current_animation().find("1h_attack")

func attack(tar):
	for enemy in game.enemies:
		if enemy.get_instance_id() == tar.get_instance_id():
			enemy.take_damage(1)

func move_direct():
	velocity = (destination - position).normalized() * SPEED
	velocity = move_and_slide(velocity)

func move_along_path(distance):
	avoidance_weight = 2
	velocity_weight = 1
	var last_point = position
	while path.size():
		
		var distance_between_points = last_point.distance_to(path[0])
		# The position to move to falls between two points.
		if distance <= distance_between_points:
			var new_position = last_point.linear_interpolate(path[0], distance / distance_between_points)
			velocity = (new_position - position).normalized()

#			if 0 != get_slide_count():
#				var collider = get_slide_collision(0).collider
#				if collider:
#					if !game.is_door(collider.get_instance_id()):
#						avoidance_force = (position - collider.position).normalized()
#						velocity = (avoidance_force * avoidance_weight + velocity * velocity_weight).normalized()
#						path.set(0, path[0] + velocity * distance)
			
#			raycast_path.set_cast_to(path[0] - position)
#			if raycast_path:
#				if raycast_path.is_colliding():
#					velocity = (raycast_path.get_collision_normal() * 0.5 + velocity).normalized()
					
			velocity = move_and_slide(velocity * SPEED)
			return
		# The position is past the end of the segment.
		distance -= distance_between_points
		last_point = path[0]
		path.remove(0)
	# The character reached the end of the path.
	position = last_point

func update_navigation_path(start_position, end_position):
	path = game.map.find_path(start_position, end_position)
	if path:
		for i in range(path.size()):
			var tile_center = path[i]
			tile_center.x -= 32
			path[i] = tile_center
	#	path = game.navigation.get_simple_path(start_position, end_position, true)
		path.remove(0) # The first point of the path is always the start_position. remove this
		# shift all paths to middle of tiles except for final point









func _draw():
	for i in range(path.size()-1):
		var from_pt = get_global_transform().xform_inv(path[i])
		var to_pt = get_global_transform().xform_inv(path[i+1])
		draw_line(from_pt, to_pt, Color.red, 2.0)
		
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var from_pt = get_global_transform().xform_inv(collision.collider.position)
		draw_circle(from_pt, 5, Color.burlywood)

	if velocity:
		var player_pos = get_global_transform().xform_inv(position)
		draw_line(player_pos, (player_pos + (velocity/SPEED)*100), Color.black, 2)

	if avoidance_force:
		var player_pos = get_global_transform().xform_inv(position)
		draw_line(player_pos, (player_pos + (avoidance_force)*100), Color.yellow, 2)
	
	if raycast:
		if raycast.is_colliding():
			var col_pt = get_global_transform().xform_inv(raycast.get_collision_point())
			var col_norm = raycast.get_collision_normal()
			draw_circle(col_pt, 5, Color.aqua)
			draw_line(col_pt,(col_pt + col_norm * 50), Color.green, 2)
			
	if raycast_path:
		if raycast_path.is_colliding():
			var path_col_pt = get_global_transform().xform_inv(raycast_path.get_collision_point())
			var path_col_norm = raycast_path.get_collision_normal()
			draw_circle(path_col_pt, 5, Color.brown)
			draw_line(path_col_pt,(path_col_pt + path_col_norm * 50), Color.green, 2)
