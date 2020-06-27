extends Node2D

# Scene components 
onready var map = $Map
onready var visibility_map = $VisibilityMap
onready var wall_map = $YSort/WallMap
onready var player = $YSort/Player

# Enemy Scene
const EnemyScene = preload("res://enemy_scenes/Enemy.tscn")
# Tile scenes
const BlockHalf = preload("res://tile_scenes/BlockHalf.tscn")
const WallHalfN = preload("res://tile_scenes/WallHalfN.tscn")
const WallHalfS = preload("res://tile_scenes/WallHalfS.tscn")
const WallHalfW = preload("res://tile_scenes/WallHalfW.tscn")
const WallHalfE = preload("res://tile_scenes/WallHalfE.tscn")
const WallHalfNE = preload("res://tile_scenes/WallHalfNE.tscn")
const WallHalfNW = preload("res://tile_scenes/WallHalfNW.tscn")
const WallHalfSE = preload("res://tile_scenes/WallHalfSE.tscn")
const WallHalfSW = preload("res://tile_scenes/WallHalfSW.tscn")
const DoorNE = preload("res://tile_scenes/DoorNE.tscn")
const DoorNW = preload("res://tile_scenes/DoorNW.tscn")
const DoorSE = preload("res://tile_scenes/DoorSE.tscn")
const DoorSW = preload("res://tile_scenes/DoorSW.tscn")
const DoorOpenNE = preload("res://tile_scenes/DoorOpenNE.tscn")
const DoorOpenSE = preload("res://tile_scenes/DoorOpenSE.tscn")
const DoorOpenSW = preload("res://tile_scenes/DoorOpenSW.tscn")
const DoorOpenNW = preload("res://tile_scenes/DoorOpenNW.tscn")
const StairsNE = preload("res://tile_scenes/StairsNE.tscn")
const CeramicPot = preload("res://tile_scenes/CeramicPot.tscn")
# Tile types
enum Tile {Ground, Stairs_NE, Block, Fog, Door_NE, Door_SE, Door_SW, Door_NW, Door_Open_NE, Door_Open_SE, Door_Open_SW, Door_Open_NW, Wall_Half_N, Wall_Half_NE, Wall_Half_E, Wall_Half_SE, Wall_Half_S, Wall_Half_SW, Wall_Half_W, Wall_Half_NW, Ceramic_Pot}
const TileScene = [-1, StairsNE, BlockHalf, -1, DoorNE, DoorSE, DoorSW, DoorNW, DoorOpenNE, DoorOpenSE, DoorOpenSW, DoorOpenNW, WallHalfN, WallHalfNE, WallHalfE, WallHalfSE, WallHalfS, WallHalfSW, WallHalfW, WallHalfNW, CeramicPot]
const TileOffset = [-1, Vector2(0, 32), Vector2(0, 64), -1, Vector2(0, 32), Vector2(0, 88), Vector2(0, 80), Vector2(0, 32), Vector2(0, 32), Vector2(0, 64), Vector2(0, 64), Vector2(0, 32), Vector2(0, 32), Vector2(0, 16), Vector2(0, 64), Vector2(0, 64), Vector2(0, 64), Vector2(0, 80), Vector2(0, 32), Vector2(0, 32), Vector2(0, 0)]
# Stage constants
const TILE_SIZE = {x = 256.0, y = 128.0}
const STAGE_SIZES = [
	Vector2(30, 30),
	Vector2(35, 35),
	Vector2(40, 40),
	Vector2(45, 45),
	Vector2(50, 50)
]
const STAGE_ROOM_COUNTS = [5,7,9,12,15]
const STAGE_ENEMY_COUNTS = [5, 8, 12, 18, 26]
const STAGE_ITEM_COUNTS = [2, 4, 6, 8, 10]
const MIN_ROOM_DIMENSION = 5
const MAX_ROOM_DIMENSION = 8

# Player vars
var player_tile

# Stage vars
var stage_num = 0
var tile_map = []
var tile_instance_map = []
var object_list = []
var object_instance_list = []
var rooms = []
var enemies = []
var stage_size
var pathfinding

# Object vars
var object
var object_tile

# ==============================================================================
# ---------------------------- Stage Mechanics ---------------------------------
# ==============================================================================

# Called when the node enters the scene tree for the first time.
func _ready():
	var screen_size = OS.get_screen_size() # get screen size of game
	var window_size = Vector2(screen_size.x,screen_size.y) # set window size of game
	OS.set_window_size(window_size) # scale viewport to 1280 x 720
	OS.set_window_position(screen_size * 0.5 - window_size * 0.5) # center screen
	randomize() # randomize seed
	build_stage() # build the stage
	player.visible = true

# Construct one stage based on the stage number
func build_stage():
	
	# start with a blank map
	rooms.clear()
	tile_map.clear()
	tile_instance_map.clear()
	map.clear()
	
	# clear all enemies from map
	for enemy in enemies:
		enemy.remove()
	enemies.clear()
	
	# new AStar graph for pathfinding
	pathfinding = AStar.new()
	
	#  Fill stage with blocks based on stage size
	stage_size = STAGE_SIZES[stage_num]
	for x in range(stage_size.x):
		tile_map.append([])
		tile_instance_map.append([])
		for y in range(stage_size.y):
			tile_map[x].append(Tile.Block)
			tile_instance_map[x].append([])
			set_tile(x, y, Tile.Block)


	# Calculate free regions around rooms based on stage size
	var free_regions = [Rect2(Vector2(2, 2), stage_size - Vector2(4, 4))]

	# Get number of rooms for this stage
	var num_rooms = STAGE_ROOM_COUNTS[stage_num]

	# Add rooms and connect them to each other
	for _i in range(num_rooms):
		add_room(free_regions)
		if free_regions.empty():
			break
	connect_rooms()

	# Place player at start of stage
	var start_room = rooms.front()
	var player_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2)
	var player_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2)
	player_tile = Vector2(player_x, player_y)
	
	# Place enemies throughout stage
	var num_enemies = STAGE_ENEMY_COUNTS[stage_num]
	for _i in range(num_enemies):
		var room = rooms[1 + randi() % (rooms.size() - 1)]
		var x = room.position.x + 1 + randi() % int(room.size.x - 2)
		var y = room.position.y + 1 + randi() % int(room.size.y - 2)
		
		var blocked = false
		for enemy in enemies:
			if enemy.tile.x == x && enemy.tile.y ==y:
				blocked = true
				break
		
		if !blocked:
			var enemy = Enemy.new(self, 3, x, y)
			enemies.append(enemy)

	
	# place an object in the start room
	var object_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2)
	var object_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2)
	add_object(object_x, object_y, Tile.Ceramic_Pot)

	# Place stairs to get to next stage
	var end_room = rooms.back()
	var stairs_x = end_room.position.x + 1 + randi() % int(end_room.size.x - 2)
	var stairs_y = end_room.position.y + 1 + randi() % int(end_room.size.y - 2)
	set_tile(stairs_x, stairs_y, Tile.Stairs_NE)

	# Wait and update stage visuals 	
	yield(get_tree().create_timer(1), "timeout") ## gives time to update visuals
	call_deferred("update_visuals")

# Set visuals for current state
func update_visuals():
	# Update player position
	var position = map.map_to_world(player_tile)
	player.position.x = position.x
	player.position.y = position.y
	

# ==============================================================================
# ------------------------- Stage Building Mechanics ---------------------------
# ==============================================================================

# Add a room to the stage
func add_room(free_regions):
	var region = free_regions[randi() % free_regions.size()]
	
	var size_x = MIN_ROOM_DIMENSION
	if region.size.x > MIN_ROOM_DIMENSION:
		size_x += randi() % int(region.size.x - MIN_ROOM_DIMENSION)
		
	var size_y = MIN_ROOM_DIMENSION
	if region.size.y > MIN_ROOM_DIMENSION:
		size_y += randi() % int(region.size.y - MIN_ROOM_DIMENSION)

	size_x = min(size_x, MAX_ROOM_DIMENSION)
	size_y = min(size_y, MAX_ROOM_DIMENSION)
	
	var start_x = region.position.x
	if region.size.x > size_x:
		start_x += randi() % int(region.size.x - size_x)

	var start_y = region.position.y
	if region.size.y > size_y:
		start_y += randi() % int(region.size.y - size_y)

	var room = Rect2(start_x, start_y, size_x, size_y)
	rooms.append(room)
	
	for x in range(start_x, start_x + size_x):
		if x == start_x: 
			set_tile(x, start_y, Tile.Wall_Half_N) 
		elif x == (start_x + size_x - 1): 
			set_tile(x, start_y, Tile.Wall_Half_E)
		else: 
			set_tile(x, start_y, Tile.Wall_Half_NE)
			
		if x == start_x:
			set_tile(x, start_y + size_y - 1, Tile.Wall_Half_W)
		elif x == (start_x + size_x - 1): 
			set_tile(x, start_y + size_y - 1, Tile.Wall_Half_S)
		else: 
			set_tile(x, start_y + size_y - 1, Tile.Wall_Half_SW)

	for y in range(start_y + 1, start_y + size_y - 1):
		set_tile(start_x, y, Tile.Wall_Half_NW)
		set_tile(start_x + size_x -1, y, Tile.Wall_Half_SE)
		
		for x in range(start_x + 1, start_x + size_x - 1):
			set_tile(x, y, Tile.Ground)

	cut_regions(free_regions, room)

# Add an object at location 
func add_object(x, y, type):
	var new_object = BreakableObject.new(self, x, y, type)
	# add object to lists
	object_instance_list.append(new_object)
	object_list.append(type)

# Place tile type at location
func set_tile(x, y, type):
	# delete tile instance at location
	if typeof(tile_instance_map[x][y]) == TYPE_OBJECT:
		tile_instance_map[x][y].queue_free()
		tile_instance_map[x][y] = -1
	# save tile type in map
	tile_map[x][y] = type
	
	# create tile on position x, y
	if type == Tile.Ground:
		map.set_cell(x, y, type)
		clear_path(Vector2(x, y))
	else:
		create_tile(x, y, type)
		
		# fill ground undearneath the wall and tiles
		if is_wall(type) || is_door(type):
			map.set_cell(x, y, Tile.Ground)

# Create tile instance from scene and position it on the map
func create_tile(x, y, tile_type):
	
	# create and add to map
	var tile = TileScene[tile_type].instance()
	wall_map.add_child(tile)
	
	# set tile position with offset
	var position = map.map_to_world(Vector2(x, y))
	var tile_offset = TileOffset[tile_type]
	tile.position.x = position.x + tile_offset.x
	tile.position.y = position.y + tile_offset.y
	tile_instance_map[x][y] = tile


# return the Tile type of the given instance
func get_instance_type(instance):
	# find location of instance in tile_instance_map or object_instance_map
	for x in range(stage_size.x):
		for y in range(stage_size.y):
			if typeof(tile_instance_map[x][y]) == TYPE_OBJECT:
				if tile_instance_map[x][y].get_instance_id() == instance.get_instance_id():
					return tile_map[x][y]
	for i in range(object_instance_list.size()):
		if object_instance_list[i].get_instance_id() == instance.get_instance_id():
			return object_list[i]

# return the object by id
func get_object_by_id(id):
	for object in object_instance_list:
		if object.get_instance_id() == id:
			return object 

# check if tile is a wall
func is_wall(type):
	return type == Tile.Wall_Half_N || Tile.Wall_Half_NE || Tile.Wall_Half_E || Tile.Wall_Half_SE || Tile.Wall_Half_S || Tile.Wall_Half_SW || Tile.Wall_Half_W || Tile.Wall_Half_NW
	
# clear path
func clear_path(tile):
	var new_point = pathfinding.get_available_point_id()
	pathfinding.add_point(new_point, Vector3(tile.x, tile.y, 0))
	var points_to_connect = []
	
	if tile.x > 0 && tile_map[tile.x -1][tile.y] == Tile.Ground:
		points_to_connect.append(pathfinding.get_closest_point(Vector3(tile.x - 1, tile.y, 0)))
	if tile.y > 0 && tile_map[tile.x][tile.y - 1] == Tile.Ground:
		points_to_connect.append(pathfinding.get_closest_point(Vector3(tile.x, tile.y - 1, 0)))
	if tile.x < stage_size.x - 1 && tile_map[tile.x + 1][tile.y] == Tile.Ground:
		points_to_connect.append(pathfinding.get_closest_point(Vector3(tile.x + 1, tile.y, 0)))
	if tile.y < stage_size.y - 1 && tile_map[tile.x][tile.y + 1] == Tile.Ground:
		points_to_connect.append(pathfinding.get_closest_point(Vector3(tile.x, tile.y + 1, 0)))

	for point in points_to_connect:
		pathfinding.connect_points(point, new_point)

func tile_to_pixel_center(x, y):
	return Vector2((x + 0.5) * TILE_SIZE.x, (y+ 0.5) * TILE_SIZE.y)
	
func connect_rooms():
	# Build an AStar graph of the area where we can add corridors
	
	var block_graph = AStar.new()
	var point_id = 0
	for x in range(stage_size.x):
		for y in range(stage_size.y):
			if tile_map[x][y] == Tile.Block:
				block_graph.add_point(point_id, Vector3(x, y, 0))
				
				# Connect to left if also block
				if x > 0 && tile_map[x - 1][y] == Tile.Block:
					var left_point = block_graph.get_closest_point(Vector3(x - 1, y, 0))
					block_graph.connect_points(point_id, left_point)
					
				# Connect to above if also block
				if y > 0 && tile_map[x][y - 1] == Tile.Block:
					var above_point = block_graph.get_closest_point(Vector3(x, y - 1, 0))
					block_graph.connect_points(point_id, above_point)
					
				point_id += 1
				
	# Build an AStar graph of room connnections
	var room_graph = AStar.new()
	point_id = 0
	for room in rooms:
		var room_center = room.position + room.size / 2
		room_graph.add_point(point_id, Vector3(room_center.x, room_center.y, 0))
		point_id += 1
	
	# Add random connections until everything is connected
	while !is_everything_connected(room_graph):
		add_random_connections(block_graph, room_graph)
		
func is_everything_connected(graph):
	var points = graph.get_points()
	var start = points.pop_back()
	for point in points:
		var path = graph.get_point_path(start, point)
		if !path:
			return false
	return true

func add_random_connections(block_graph, room_graph):
	# Pick rooms to connect
	
	var start_room_id = get_least_connected_point(room_graph)
	var end_room_id = get_nearest_unconnected_point(room_graph, start_room_id)
	
	# Pick door locations
	var start_position = pick_random_door_location(rooms[start_room_id])
	var end_position = pick_random_door_location(rooms[end_room_id])
	
	# Find a path to connect the doors to each other
	var closest_start_point = block_graph.get_closest_point(start_position)
	var closest_end_point = block_graph.get_closest_point(end_position)
	
	var path = block_graph.get_point_path(closest_start_point, closest_end_point)
	assert(path)
	
	# Add path to the map
	path = Array(path)
	
	# Set door tiles
	set_door_tile(start_position.x, start_position.y, false)
	set_door_tile(end_position.x, end_position.y, false)
	
	for position in path:
		set_tile(position.x, position.y, Tile.Ground)

	room_graph.connect_points(start_room_id, end_room_id)

# set the door tile, open or closed based on the wall orientation next to it
func set_door_tile(position_x, position_y, open):
	if Tile.Wall_Half_NE == tile_map[position_x - 1][position_y] || Tile.Wall_Half_NE == tile_map[position_x + 1][position_y]:
		if open:
			set_tile(position_x, position_y, Tile.Door_Open_NE)
		else:
			set_tile(position_x, position_y, Tile.Door_NE)
	elif Tile.Wall_Half_SE == tile_map[position_x][position_y - 1] || Tile.Wall_Half_SE == tile_map[position_x][position_y + 1]:
		if open:
			set_tile(position_x, position_y, Tile.Door_Open_SE)
		else:
			set_tile(position_x, position_y, Tile.Door_SE)
	elif Tile.Wall_Half_SW == tile_map[position_x - 1][position_y] || Tile.Wall_Half_SW == tile_map[position_x + 1][position_y]:
		if open:
			set_tile(position_x, position_y, Tile.Door_Open_SW)
		else:
			set_tile(position_x, position_y, Tile.Door_SW)
	elif Tile.Wall_Half_NW == tile_map[position_x][position_y - 1] || Tile.Wall_Half_NW == tile_map[position_x][position_y + 1]:
		if open:
			set_tile(position_x, position_y, Tile.Door_Open_NW)
		else:
			set_tile(position_x, position_y, Tile.Door_NW)

func is_door(type):
	return type == Tile.Door_NE || type == Tile.Door_SE || type == Tile.Door_SW || type == Tile.Door_NW || type == Tile.Door_Open_NE || type == Tile.Door_Open_SE || type == Tile.Door_Open_SW || type == Tile.Door_Open_NW

func is_door_closed(type):
	return type == Tile.Door_NE || type == Tile.Door_SE || type == Tile.Door_SW || type == Tile.Door_NW

func is_breakable_object(type):
	return type == Tile.Ceramic_Pot

func hurt(target):
	target.health -= 1
	if target.health <= 0:
		target.remove()
		var index = object_instance_list.find(target)
		object_instance_list.erase(object_instance_list[index])
		object_list.erase(object_list[index])

func get_least_connected_point(graph):
	var point_ids = graph.get_points()
	
	var least
	var tied_for_least = []
	
	for point in point_ids:
		var count = graph.get_point_connections(point).size()
		if !least || count < least:
			least = count
			tied_for_least = [point]
		elif count == least:
			tied_for_least.append(point)
	
	return tied_for_least[randi() % tied_for_least.size()]
	
func get_nearest_unconnected_point(graph, target_point):
	var target_position = graph.get_point_position(target_point)
	var point_ids = graph.get_points()
	
	var nearest
	var tied_for_nearest = []
	
	for point in point_ids:
		if point == target_point:
			continue
		
		var path = graph.get_point_path(point, target_point)
		if path:
			continue
			
		var dist = (graph.get_point_position(point) - target_position).length()
		if !nearest || dist < nearest:
			nearest = dist
			tied_for_nearest = [point]
		elif dist == nearest:
			tied_for_nearest.append(point)
	
	return tied_for_nearest[randi() % tied_for_nearest.size()]
	
func pick_random_door_location(room):
	var options = []
	
	# Top and bottom walls
	
	for x in range(room.position.x + 1, room.end.x - 2):
		options.append(Vector3(x, room.position.y, 0))
		options.append(Vector3(x, room.end.y -1, 0))
		
	# Left and right walls
	
	for y in range(room.position.y + 1, room.end.y - 2):
		options.append(Vector3(room.position.x, y, 0))
		options.append(Vector3(room.end.x - 1, y, 0))
		
	return options[randi() % options.size()]


func cut_regions(free_regions, region_to_remove):
	var removal_queue = []
	var addition_queue = []
	
	for region in free_regions:
		if region.intersects(region_to_remove):
			removal_queue.append(region)
			
			var leftover_left = region_to_remove.position.x - region.position.x - 1
			var leftover_right = region.end.x - region_to_remove.end.x - 1
			var leftover_above = region_to_remove.position.y - region.position.y - 1
			var leftover_below = region.end.y - region_to_remove.end.y - 1
			
			if leftover_left >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(region.position, Vector2(leftover_left, region.size.y)))
			if leftover_right >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(Vector2(region_to_remove.end.x+1,region.position.y),Vector2(leftover_right,region.size.y)))
			if leftover_above >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(region.position, Vector2(region.size.x, leftover_above)))
			if leftover_below >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(Vector2(region.position.x, region_to_remove.end.y + 1), Vector2(region.size.x, leftover_below)))
	
	for region in removal_queue:
		free_regions.erase(region)
	for region in addition_queue:
		free_regions.append(region)

# ==============================================================================
# ------------------------- Breakable Object Class -----------------------------
# ==============================================================================

class BreakableObject extends Reference:
	
	# Object variables
	var node
	var health

	# Called when the object is initialized.
	func _init(game, x, y, type):
		node = TileScene[type].instance()
		health = 3
		var world_pos = game.map.map_to_world(Vector2(x, y))
		node.position.x = world_pos.x
		node.position.y = world_pos.y
		game.wall_map.add_child(node)
		
	func get_instance_id():
		return node.get_instance_id()

	# Remove the object node
	func remove():
		node.queue_free()

# ==============================================================================
# ----------------------------- Physics Process --------------------------------
# ==============================================================================

#func _physics_process(delta):
#	# move all enemies in map
#	for enemy in enemies:
#		enemy.move(delta)
		
# ==============================================================================
# ------------------------------- Enemy Class ----------------------------------
# ==============================================================================

class Enemy extends Reference: 

	# Enemy Constants
	var SPEED = 100
	# Enemy variables
	var game
	var node
	var anim_player
	var id
	var level
	var tile
	var max_hp
	var hp
	var dead = false
	var player_seen = false

	# Called when the object is initialized.
	func _init(game_state, enemy_level, x, y):
		game = game_state
		level = enemy_level
		id = "brown_hellspawn"
		max_hp = level
		hp = max_hp
		tile = Vector2(x, y)
		node = EnemyScene.instance()
		node.position = game.map.map_to_world(tile)
		anim_player = node.get_node("EnemySprite/AnimationPlayer")
		anim_player.play(id + "_idle_s")
		game.add_child(node)

	# Remove the item node after processing
	func remove():
		node.queue_free()

	# Deal damage to this enemy
	func take_damage(dmg):
		if dead:
			return
		hp = max(0, hp - dmg)
		node.get_node("EnemySprite/EnemyHP").rect_size.x = TILE_SIZE.x * hp / max_hp
		if hp == 0:
			dead = true
			game.enemies.erase(self)
			remove()
	
	# Get instance id
	func get_instance_id():
		return node.get_instance_id()
