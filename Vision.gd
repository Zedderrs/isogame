extends Area2D
onready var game = get_tree().get_root().get_node("Game")
onready var enemies_in_range = []

func _process(_delta):
	#remove null entries
	for enemy in enemies_in_range:
			if enemy_in_los(enemy):
				enemy.visible = true
			else:
				enemy.visible = false

func _on_Area2D_body_entered(body): # reveal all in vision
	if is_enemy(body):
		enemies_in_range.append(body)
	else:
		body.visible = true

func is_enemy(body):
	var is_enemy = false
	for enemy in game.enemies: # only reveal enemy if in line of sight
		if body.get_instance_id() == enemy.get_instance_id():
			is_enemy = true
	return is_enemy

func enemy_in_los(body):
	game.player.raycast.set_cast_to(body.position - game.player.position)
	game.player.raycast.force_raycast_update()
	return !game.player.raycast.is_colliding()


func _on_VisionArea2D2_body_exited(body):
	if is_enemy(body):
		enemies_in_range.erase(body)
