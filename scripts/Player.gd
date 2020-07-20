extends KinematicBody2D

# animation nodes
onready var body_animation_player = $BodySprite/BodyAnimationPlayer
onready var hair_animation_player = $HairSprite/HairAnimationPlayer
onready var top_animation_player = $TopSprite/TopAnimationPlayer
onready var bottom_animation_player = $BottomSprite/BottomAnimationPlayer
onready var weapon_animation_player = $WeaponSprite/WeaponAnimationPlayer
onready var effect_animation_player = $Effectsprite/EffectAnimationPlayer
onready var raycast = $RayCast2D

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

# scene vars
onready var game = get_tree().get_root().get_node("Game")
var space_graph

# player animations
onready var gender = Gender.Male
onready var body = Body.Elf
onready var hair = Hair.Elf
onready var top = Top.Elf
onready var bottom = Bottom.Elf
onready var weapon = Weapon.Sword
var current_body_animation
# player state
onready var action = Action.Idle
onready var direction = Dir.S
onready var current_action = action
onready var current_direction = direction
var target
var interrupt_attack
# player attributes
onready var attack_range = 100
onready var hp_max = 10
onready var hp = hp_max
onready var xp = 2
onready var xp_max = 10
# player movement
onready var path = []
onready var velocity = Vector2()
onready var destination = position
# debug tool vars
var from_pt
var to_pt

# ==============================================================================
# ------------------ Player Input and Movement Mechanics -----------------------
# ==============================================================================

func _input(event):
	if event.is_action_pressed("left_click"):
		destination = get_global_mouse_position()
		if is_hovering_over_ground():
			update_navigation_path(position, get_global_mouse_position())
		if target && 0 == Input.get_current_cursor_shape(): # clear target if clicked to move
			target.health_bar.visible = false
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
	raycast.set_cast_to(destination - position)
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
	if tile.x < 0 || tile.y < 0 || tile.x >= game.stage_size.x || tile.y >= game.stage_size.y:
		return false
	else:
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
	var last_point = position
	while path.size():
		
		var distance_between_points = last_point.distance_to(path[0])
		# The position to move to falls between two points.
		if distance <= distance_between_points:
			var new_position = last_point.linear_interpolate(path[0], distance / distance_between_points)
			velocity = (new_position - position).normalized()
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

func take_damage(dmg):
	hp = hp - dmg

# ==============================================================================
# ------------------------------- Debugging ------------------------------------
# ==============================================================================

func _draw():
	# pathfinding for character walking
	for i in range(path.size()-1):
		var from_pt = get_global_transform().xform_inv(path[i])
		var to_pt = get_global_transform().xform_inv(path[i+1])
		draw_line(from_pt, to_pt, Color.red, 2.0)
	
	# collision center of object from move_slide
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var from_pt = get_global_transform().xform_inv(collision.collider.position)
		draw_circle(from_pt, 5, Color.burlywood)

	# velocity vector
	if velocity:
		var player_pos = get_global_transform().xform_inv(position)
		draw_line(player_pos, (player_pos + (velocity/SPEED)*100), Color.black, 2)

	if raycast:
		if raycast.is_colliding():
			var col_pt = get_global_transform().xform_inv(raycast.get_collision_point())
			var col_norm = raycast.get_collision_normal()
			draw_circle(col_pt, 5, Color.aqua)
			draw_line(col_pt,(col_pt + col_norm * 50), Color.green, 2)
