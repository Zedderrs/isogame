extends KinematicBody2D
# scene components
onready var anim_player = $EnemySprite/AnimationPlayer

# enemy constants
const SPEED = 100

# enemy animation dictionary
var Type = {"Brown": "brown_"}
var EnemyID = {"Hellspawn": "hellspawn_"}
var Action = {"Idle": "idle", "Run": "run"}
var Dir = {"N":"_n", "NE":"_ne", "E":"_e", "SE":"_se", "S":"_s", "SW":"_sw", "W":"_w", "NW":"_nw"}

# enemy scene variables
var player_seen
var game
var type
var id
var action
var direction

# Called when the node enters the scene tree for the first time.
func _ready():
	player_seen = false
	game = get_tree().get_root().get_node("Game")
	# enemy animations
	type = Type.Brown
	id = EnemyID.Hellspawn
	action = Action.Idle
	direction = Dir.S

func _physics_process(delta):
		if self.visible:
			player_seen = true
		if !player_seen:
			return
		var enemy_tile = game.map.world_to_map(position)
		var player_tile = game.map.world_to_map(game.player.position)
		var enemy_point = game.pathfinding.get_closest_point(Vector3(enemy_tile.x, enemy_tile.y, 0))
		var player_point = game.pathfinding.get_closest_point(Vector3(player_tile.x, player_tile.y, 0))
		var path = game.pathfinding.get_point_path(enemy_point, player_point)
		if path && path.size() > 1:
			action = Action.Run
			var move_to_tile = Vector2(path[1].x, path[1].y)
			var move_to_position = game.map.map_to_world(move_to_tile)
			
			#var move_direction = (move_to_position - self.position).normalized()
			#var motion = move_direction * SPEED * delta
			
			var move_direction = (move_to_position - self.position).normalized()
			var motion = move_direction * SPEED * delta
			position += motion
			direction = game.player.get_cardinal_direction(move_direction)
			anim_player.play(type + id + action + direction)
		else:
			action = Action.Idle
			anim_player.play(type + id + action + direction)


func _on_Enemy_mouse_entered():
	Input.set_default_cursor_shape(2)

func _on_Enemy_mouse_exited():
	Input.set_default_cursor_shape(0)
