extends Node2D

var game
var from
var to
var i

func _process(_delta):
	if game.player.path:
			from = game.player.position #Vector2(game.player.position.x, game.player.position.y)
			to = Vector2(game.player.path[0].x, game.player.path[0].y) 
			update()
			
func _draw():
	if from && to:
		draw_circle(from,500.00,Color.red) 
		draw_line(Vector2(from.x,from.y), Vector2(to.x, to.y), Color(1.00,0.00,0.00))

# Called when the node enters the scene tree for the first time.
func _ready():
	game = get_tree().get_root().get_node("Game")
	i = 0
