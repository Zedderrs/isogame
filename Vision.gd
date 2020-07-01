extends Area2D
# scene vars
var game

# Called when the node enters the scene tree for the first time.
func _ready():
	game = get_tree().get_root().get_node("Game")

func _physics_process(_delta):
	pass

func _on_Area2D_body_entered(body):
#	var tile_position = game.map.world_to_map(body.position)
#	game.map.set_cellv(Vector2(tile_position.x, tile_position.y), game.Tile.Ground.Type)
#	var pos = game.map.world_to_map(game.player.position)
#	game.map.set_cell(pos.x,pos.y,-1)
#		game.Tile.Filler.Type
	body.visible = true
