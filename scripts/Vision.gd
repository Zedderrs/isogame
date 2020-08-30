extends Area2D
onready var game = get_tree().get_root().get_node("Game")
onready var los = $LineOfSight
onready var objects_in_range = []
onready var enemies_in_range = []

func _process(_delta):
	# check if an object in range is within line of sight. 
	# set visible if it does
	for object in objects_in_range:
			if object_in_los(object):
				set_object_visible(object)

	# check if an ojbect in range is within line of sight. 
	# set visible if does. hide if it isn't in line of sight.
	for enemy in enemies_in_range:
		if object_in_los(enemy):
			enemy.visible = true
		else:
			enemy.visible = false

func is_enemy(body):
	var is_enemy = false
	for enemy in game.enemies: # only reveal enemy if in line of sight
		if body.get_instance_id() == enemy.get_instance_id():
			is_enemy = true
	return is_enemy

func object_in_los(body):
	los.set_cast_to(game.get_tile_center_position(body.position) - game.player.position)
	los.force_raycast_update()
	return !los.is_colliding() || (los.is_colliding() && los.get_collider().get_instance_id() == body.get_instance_id())

func set_object_visible(object):
	# set the object as visible as well as neighbouring objects
	object.visible = true
	var tile = game.map.world_to_map(object.position)
	if null == game.map.map_size: return
	if (tile.x + 1) <= (game.map.map_size.x - 1):
		set_neighbour_visible(tile.x + 1, tile.y)
	if (tile.x - 1) >= 0:
		set_neighbour_visible(tile.x - 1, tile.y)
	if (tile.y + 1) <= (game.map.map_size.y - 1):
		set_neighbour_visible(tile.x, tile.y + 1)
	if (tile.y - 1) >= 0:
		set_neighbour_visible(tile.x, tile.y - 1)

func set_neighbour_visible(x, y):
	if typeof(game.tile_instance_map[x][y]) == TYPE_OBJECT:
		game.tile_instance_map[x][y].visible = true

func _on_Area2D_body_entered(body):
	if is_enemy(body):
		enemies_in_range.append(body)
	else:
		objects_in_range.append(body)

func _on_VisionArea2D2_body_exited(body):
	if is_enemy(body):
		enemies_in_range.erase(body)
	else:
		objects_in_range.erase(body)
