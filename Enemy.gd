extends KinematicBody2D
# scene components
onready var anim_player = $EnemySprite/AnimationPlayer
onready var game = get_tree().get_root().get_node("Game")

# enemy constants
const SPEED = 100

# enemy animation dictionary
var Type = {"Brown": "brown_"}
var EnemyID = {"Hellspawn": "hellspawn_"}
var Action = {"Idle": "idle", "Run": "run"}
var Dir = {"N":"_n", "NE":"_ne", "E":"_e", "SE":"_se", "S":"_s", "SW":"_sw", "W":"_w", "NW":"_nw"}

# enemy scene variables
var player_seen
var type
var id
var action
var direction
var targeted

# Called when the node enters the scene tree for the first time.
func _ready():
	player_seen = false
	# enemy animations
	type = Type.Brown
	id = EnemyID.Hellspawn
	action = Action.Idle
	direction = Dir.S
	# enemy targeted status
	targeted = false

func _physics_process(_delta):
		if self.visible:
			player_seen = true
		if !player_seen:
			return
		
		if Input.is_mouse_button_pressed(1) && targeted:
				game.player.target = self

		action = Action.Idle
		anim_player.play(type + id + action + direction)


func _on_Enemy_mouse_entered():
	Input.set_default_cursor_shape(2)
	targeted = true

func _on_Enemy_mouse_exited():
	Input.set_default_cursor_shape(0)
	targeted = false
