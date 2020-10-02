extends KinematicBody2D

# animation nodes
onready var body_animation_player = $BodySprite/BodyAnimationPlayer
onready var hair_animation_player = $HairSprite/HairAnimationPlayer
onready var top_animation_player = $TopSprite/TopAnimationPlayer
onready var bottom_animation_player = $BottomSprite/BottomAnimationPlayer
onready var weapon_animation_player = $WeaponSprite/WeaponAnimationPlayer
onready var effect_animation_player = $EffectSprite/EffectAnimationPlayer
onready var effect = $EffectSprite
onready var raycast = $RayCast2D
onready var spell_cooldown_timer = $SpellTimer

# animation dictionary
var Gender = {"Male": "male_"}
var Body = {"Elf": "elf_body"}
var Top = {"Elf": "elf_top"}
var Hair = {"Elf": "elf_hair"}
var Bottom = {"Elf": "elf_bottom"}
var Weapon = {"Sword": "weapon_sword"}
var Action = {"Idle": "_idle", "Run": "_run", "Attack": "_1h_attack", "Cast": "_casting", "Punch":"_punch"} 
var Dir = {"N":"_n", "NE":"_ne", "E":"_e", "SE":"_se", "S":"_s", "SW":"_sw", "W":"_w", "NW":"_nw"}
var Spell = {"Lightning": "lightning"}

# scene constants
const SPEED = 250 # How fast the player will move (pixels/sec).

# scene vars
onready var game = get_tree().get_root().get_node("Game")
var space_graph

# player animations and inventory
onready var gender = Gender.Male
onready var body = Body.Elf
onready var hair = Hair.Elf
onready var top
onready var bottom
onready var weapon
onready var spell = Spell.Lightning
var current_body_animation
# player state
onready var action = Action.Idle
onready var direction = Dir.S
onready var current_action = action
onready var current_direction = direction
onready var melee = true
var target
var spell_target
var interrupt
# player attributes
onready var attack_range = 100
onready var cast_range = 600
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
	if event.is_action_pressed("left_click") || event.is_action_pressed("right_click"):
		destination = get_global_mouse_position()
		# Melee mode if last action was a left click
		melee = event.is_action_pressed("left_click")
		interrupt = false
#		if is_hovering_over_ground():
#			update_navigation_path(position, get_global_mouse_position())
		if target && 0 == Input.get_current_cursor_shape(): # clear target if clicked to move
			target.health_bar.visible = false
			target = null
			interrupt = true
	
	if event.is_action_pressed("left",true) && !event.is_action_pressed("right",true):
		game.print_msg('pressed left')
		destination = destination + Vector2(-1000,0)
	
	if event.is_action_pressed("right",true) && !event.is_action_pressed("left",true):
		game.print_msg('pressed right')
		destination = destination + Vector2(1000,0)
	
	if !event.is_action_pressed("left",true) && !event.is_action_pressed("right",true):
		game.print_msg('released left and right')
		destination.x = self.position.x
	
	if event.is_action_pressed("up") && !event.is_action_pressed("down"):
		game.print_msg('pressed up')
		destination = destination + Vector2(0,-1000)
		
	if event.is_action_pressed("down") && !event.is_action_pressed("up"):
		game.print_msg('pressed down')
		destination = destination + Vector2(0,1000)

	if !event.is_action_pressed("up") && !event.is_action_pressed("down"):
		game.print_msg('released up and down')
		destination.y = self.position.y
	
	
	elif event.is_action_released("down"):
		destination.y = self.position.y
	
func _physics_process(delta):
	if Input.is_mouse_button_pressed(1) || Input.is_mouse_button_pressed(2): # while mouse left click is held down, update the destination
		destination = get_global_mouse_position()
#		if is_hovering_over_ground():
#			update_navigation_path(position, get_global_mouse_position())
	act(delta)
	direction = get_cardinal_direction(velocity)
	set_animations()
	
	if game.debug_mode:
		update() #draw debug
	
func act(_delta):
	raycast.set_cast_to(destination - position)
	if can_attack():
		velocity = (destination - position).normalized() * SPEED
		if is_equipped(weapon):
			action = Action.Attack
		else:
			action = Action.Punch
	elif can_cast():
		velocity = (destination - position).normalized() * SPEED
		action = Action.Cast
	elif !at_destination() && !is_attacking() && !is_casting():
		var previous_position = position
		if Input.is_mouse_button_pressed(1) || Input.is_mouse_button_pressed(2):
			move_direct()
		else:
#			if is_clear_path():
				move_direct()
#			else:
#				move_along_path(delta * SPEED)
		open_door() # open the door if player collides with a door
		if previous_position.distance_squared_to(position) < 2:
			action = Action.Idle
		else:
			action = Action.Run
	else:
		action = Action.Idle

func can_attack(): 
	# can attack if not already attacking or casting, target exists, and target is within range
	return melee && !is_attacking() && !is_casting() && null != target && (target.position - position).length() <= attack_range

func can_cast():
	# can cast if not already attacking or casting, target exists, cooldown is at 0, and target is within range
	return !melee && !is_attacking() && !is_casting() && null != target && (target.position - position).length() <= cast_range && spell_cooldown_timer.is_stopped()

func at_destination():
	return (destination - position).length() < 5

func set_animations():
	if change_animation():
		play_animations()

func change_animation(): # can the animation be changed?
	if is_attacking() || is_casting(): return false
	var action_changed = action != current_action
	var direction_changed = direction != current_direction
	var no_animation_playing = "" == body_animation_player.get_current_animation()
	return action_changed || direction_changed || no_animation_playing

func play_animations():
	body_animation_player.play(gender + body + action + direction) # animate body
	hair_animation_player.play(gender + hair + action + direction) # animate hair
	if is_equipped(top):
		show_sprite($TopSprite)
		top_animation_player.play(gender + top + action + direction) # animate top
	else:
		hide_sprite($TopSprite)
	if is_equipped(bottom):
		show_sprite($BottomSprite)
		bottom_animation_player.play(gender + bottom + action + direction) # animate bottom
	else:
		hide_sprite($BottomSprite)
	if is_equipped(weapon):
		show_sprite($WeaponSprite)
		weapon_animation_player.play(gender + weapon + action + direction) # animate weapon
	else:
		# always play weapon animation even if not equipped. This is to trigger the attack at the right time.
		hide_sprite($WeaponSprite)
		weapon_animation_player.play(gender + Weapon.Sword + Action.Attack + direction) # animate weapon
	
	# update action and direction
	current_action = action
	current_direction = direction

func show_sprite(sprite):
	sprite.visible = true
	
func hide_sprite(sprite):
	sprite.visible = false

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

func is_equipped(item):
	return null != item
	
func open_door(): # opens the door if player collides with it
	for i in get_slide_count():
		var collider = get_slide_collision(i).collider
		if game.is_door_closed(collider.type):
			var map_coords = game.map.world_to_map(Vector2(collider.position.x, collider.position.y))
			game.set_door_tile(map_coords.x, map_coords.y, true)

func is_attacking():
	if interrupt:
		return false
	return -1 != body_animation_player.get_current_animation().find("1h_attack") || -1 != body_animation_player.get_current_animation().find("punch")

func is_casting():
	if interrupt:
		return false
	return -1 != body_animation_player.get_current_animation().find("casting")

func attack():
	for enemy in game.enemies:
		if target:
			if enemy.get_instance_id() == target.get_instance_id():
				enemy.take_damage(1)

func cast():
	effect_animation_player.play(spell)
	if spell == Spell.Lightning:
		spell_cooldown_timer.start(5)

func spell_attack():
	var dmg
	if spell == Spell.Lightning:
		dmg = 3
		for enemy in game.enemies:
			if spell_target:
				if enemy.get_instance_id() == spell_target.get_instance_id():
					enemy.take_damage(dmg)

func move_direct():
	velocity = (destination - position).normalized() * SPEED
	velocity = move_and_slide(velocity)

func is_clear_path():
	raycast.set_cast_to(destination-position)
	return !raycast.is_colliding()

func is_hovering_over_ground():
	var tile = game.map.world_to_map(get_global_mouse_position())
	if tile.x < 0 || tile.y < 0 || tile.x >= game.stage_size.x || tile.y >= game.stage_size.y:
		return false
	else:
		return game.is_walkable_tile(game.tile_map[tile.x][tile.y])

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
