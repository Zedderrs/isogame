extends KinematicBody2D
# scene components
onready var anim_player = $EnemySprite/EnemyAnimationPlayer
onready var health_bar  = $EnemySprite/EnemyHP
onready var raycast = $RayCast2D
onready var game = get_tree().get_root().get_node("Game")

# enemy constants
const SPEED = 100

# enemy animation dictionary
var Type = {"Brown": "brown_"}
var EnemyID = {"Hellspawn": "hellspawn_"}
var Action = {"Idle": "idle", "Run": "run", "Attack": "attack"}
var Dir = {"N":"_n", "NE":"_ne", "E":"_e", "SE":"_se", "S":"_s", "SW":"_sw", "W":"_w", "NW":"_nw"}

# enemy scene variables
var player_seen = false
var type = Type.Brown
var id = EnemyID.Hellspawn
var action = Action.Idle
var velocity = Vector2()
var destination = position
var direction = Dir.S
var targeted = false
var current_action = action
var current_direction = direction
var interrupt_attack = false
var just_arrived_at_destination = false
var target
var attack_range = 100
var is_dead = false
var level
var hp
var max_hp
var tile = Vector2()
onready var max_health_bar_length = health_bar.rect_size.x
# enemy attributes
var lazyness = 50

func _init():
	level = 3
	max_hp = level
	hp = max_hp
	self.visible = false
	
func _physics_process(_delta):
	if self.visible:
		player_seen = true
		destination = game.get_tile_center_position(game.player.position)
		target = game.player
	if !player_seen:
		wander()
	else:
		act()

	# set enemy as target if hovered and clicked
	if (Input.is_mouse_button_pressed(1) || Input.is_mouse_button_pressed(2)) && targeted:
		if game.player.target:
			health_bar.visible = false
		game.player.target = self
		game.player.spell_target = self
		health_bar.visible = true
	direction = game.player.get_cardinal_direction(velocity)
	set_animations()

func act():
	raycast.set_cast_to(destination - position)
	if can_attack():
		action = Action.Attack
	elif !at_destination() && !is_attacking():
		var previous_position = position
		if is_clear_path():
			move_direct()

		#open_door() # open the door if player collides with a door
		if previous_position.distance_squared_to(position) < 2:
			action = Action.Idle
		else:
			action = Action.Run
	else:
		action = Action.Idle
	
func wander():
	if (randi() % 100 + 1) > lazyness:
		if at_destination():
			var destination_x = position.x + game.gen_rand_num(-300, 300)
			var destination_y = position.y + game.gen_rand_num(-300, 300)
			destination = Vector2(destination_x, destination_y)
		else:
			velocity = (destination - position).normalized() * SPEED
			velocity = move_and_slide(velocity)
			action = Action.Run
			if 0 != get_slide_count():
				destination = position

func move_direct():
	velocity = (destination - position).normalized() * SPEED
	velocity = move_and_slide(velocity)

func is_clear_path():
	raycast.set_cast_to(destination-position)
	return !raycast.is_colliding()

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
	var no_animation_playing = "" == anim_player.get_current_animation()
	return action_changed || direction_changed || no_animation_playing

func play_animations():
	anim_player.play(type + id + action + direction) # animate body
	# update action and direction
	current_action = action
	current_direction = direction

func is_attacking():
	if interrupt_attack:
		return false
	return -1 != anim_player.get_current_animation().find("attack")

func attack():
	target.take_damage(1)

func take_damage(dmg):
	if is_dead:
		return
	hp = max(0, hp - dmg)
	update_health_bar()
	if hp == 0:
		die()

func die():
	is_dead = true
	game.enemies.erase(self)
	game.vision.enemies_in_range.erase(self)
	queue_free()
	Input.set_default_cursor_shape(0) # reset cursor to normal
	game.player.target = null
	game.player.spell_target = null

func _on_Enemy_mouse_entered():
	Input.set_default_cursor_shape(2)
	targeted = true

func _on_Enemy_mouse_exited():
	Input.set_default_cursor_shape(0)
	targeted = false

func update_health_bar():
	health_bar.rect_size.x = max_health_bar_length * hp / max_hp
