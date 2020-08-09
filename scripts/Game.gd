extends Node2D

# debug mode
var debug_mode = false

# Scene components 
onready var map = $Map
onready var floor_map = $FloorMap
onready var wall_map = $AboveFloor/WallMap
onready var player = $AboveFloor/Player
onready var vision = $AboveFloor/Player/Vision
onready var ui = $CanvasLayer/UI

# Cursors
onready var NormalCursor = preload("res://assets/UI/cursors/normal.png")
onready var InteractCursor = preload("res://assets/UI/cursors/interact.png")
onready var AttackCursor = preload("res://assets/UI/cursors/attack.png")

# Enemy Scene
const EnemyScene = preload("res://Scenes/Enemy.tscn")
# Tile scenes
const GrassFloor = preload("res://assets/tiles/Floors/GrassFloor.tscn")
const BlankFloor = preload("res://assets/tiles/Floors/BlankFloor.tscn")
const Filler = preload("res://assets/tiles/Walls/HalfStoneColumn.tscn")
const StairsNE = preload("res://assets/tiles/Stairs/WoodStairsNE.tscn")
const StairsSE = preload("res://assets/tiles/Stairs/WoodStairsNE.tscn")
const StairsSW = preload("res://assets/tiles/Stairs/WoodStairsNE.tscn")
const StairsNW = preload("res://assets/tiles/Stairs/WoodStairsNE.tscn")
const DoorNE = preload("res://assets/tiles/Doors/WoodDoorNE.tscn")
const DoorNW = preload("res://assets/tiles/Doors/WoodDoorNW.tscn")
const DoorSE = preload("res://assets/tiles/Doors/WoodDoorSE.tscn")
const DoorSW = preload("res://assets/tiles/Doors/WoodDoorSW.tscn")
const DoorOpenNE = preload("res://assets/tiles/Doors/WoodDoorOpenNE.tscn")
const DoorOpenNW = preload("res://assets/tiles/Doors/WoodDoorOpenNW.tscn")
const DoorOpenSE = preload("res://assets/tiles/Doors/WoodDoorOpenSE.tscn")
const DoorOpenSW = preload("res://assets/tiles/Doors/WoodDoorOpenSW.tscn")
const WallN = preload("res://assets/tiles/Walls/WoodColumn.tscn")
const WallS = preload("res://assets/tiles/Walls/WoodColumn.tscn")
const WallW = preload("res://assets/tiles/Walls/WoodColumn.tscn")
const WallE = preload("res://assets/tiles/Walls/WoodColumn.tscn")
const WallNE = preload("res://assets/tiles/Walls/WoodColumn.tscn")
const WallNW = preload("res://assets/tiles/Walls/WoodColumn.tscn")
const WallSE = preload("res://assets/tiles/Walls/WoodColumn.tscn")
const WallSW = preload("res://assets/tiles/Walls/WoodColumn.tscn")
const CeramicPot = preload("res://assets/tiles/Objects/CeramicPot.tscn")
# Tile Dictionary
var Tile = {
	"Ground": {"Type": 0, "Scene": GrassFloor, "Offset": Vector2(0,32)},
	"Filler": {"Type": 1, "Scene": Filler, "Offset": Vector2(0,32)},
	"BlankGround": {"Type": 2, "Scene": BlankFloor, "Offset": Vector2(0,32)},
	"StairsNE": {"Type": 3, "Scene": StairsNE, "Offset": Vector2(0,32)},
	"StairsSE": {"Type": 4, "Scene": StairsSE, "Offset": Vector2(0,32)},
	"StairsSW": {"Type": 5, "Scene": StairsSW, "Offset": Vector2(0,32)},
	"StairsNW": {"Type": 6, "Scene": StairsNW, "Offset": Vector2(0,32)},
	"DoorNE": {"Type": 7, "Scene": DoorNE, "Offset": Vector2(0,48)},
	"DoorSE": {"Type": 8, "Scene": DoorSE, "Offset": Vector2(0,4)},
	"DoorSW": {"Type": 9, "Scene": DoorSW, "Offset": Vector2(0,4)},
	"DoorNW": {"Type": 10, "Scene": DoorNW, "Offset": Vector2(0,48)},
	"DoorOpenNE": {"Type": 11, "Scene": DoorOpenNE, "Offset": Vector2(0,64)},
	"DoorOpenSE": {"Type": 12, "Scene": DoorOpenSE, "Offset": Vector2(0,64)},
	"DoorOpenSW": {"Type": 13, "Scene": DoorOpenSW, "Offset": Vector2(0,64)},
	"DoorOpenNW": {"Type": 14, "Scene": DoorOpenNW, "Offset": Vector2(0,64)},
	"WallN": {"Type": 15, "Scene": WallN, "Offset": Vector2(0,32)},
	"WallNE": {"Type": 16, "Scene": WallNE, "Offset": Vector2(0,32)},
	"WallE": {"Type": 17, "Scene": WallE, "Offset": Vector2(0,32)},
	"WallSE": {"Type": 18, "Scene": WallSE, "Offset": Vector2(0,32)},
	"WallS": {"Type": 19, "Scene": WallS, "Offset": Vector2(0,32)},
	"WallSW": {"Type": 20, "Scene": WallSW, "Offset": Vector2(0,32)},
	"WallW": {"Type": 21, "Scene": WallW, "Offset": Vector2(0,32)},
	"WallNW": {"Type": 22, "Scene": WallNW, "Offset": Vector2(0,32)},
	"CeramicPot": {"Type": 23, "Scene": CeramicPot, "Offset": Vector2(0,0)},
}
# Stage constants
const TILE_SIZE = {x = 64.0, y = 64.0}
const STAGE_SIZES = [
	Vector2(60, 60),
	Vector2(70, 70),
	Vector2(80, 80),
	Vector2(90, 90),
	Vector2(100, 100)
]
const STAGE_ROOM_COUNTS = [5,7,9,12,15]
const STAGE_ENEMY_COUNTS = [5, 8, 12, 18, 26]
const STAGE_ITEM_COUNTS = [2, 4, 6, 8, 10]
const MIN_ROOM_DIMENSION = 10
const MAX_ROOM_DIMENSION = 20

# Player vars
var player_tile

# Stage vars
var stage_num = 0
var tile_map = []
var tile_instance_map = []
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
	OS.set_window_size(window_size) # scale viewport to OS screen size
	OS.set_window_position(screen_size * 0.5 - window_size * 0.5) # center screen
	randomize() # randomize seed
	build_stage() # build the stage
	player.visible = true
	# set cursors
	Input.set_custom_mouse_cursor(NormalCursor, 0)
	Input.set_custom_mouse_cursor(InteractCursor, 1)
	Input.set_custom_mouse_cursor(AttackCursor, 2)


func _input(event):
	if event.is_action_pressed("console_toggle"):
		ui.msg_log_toggle_visibility()
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
			tile_map[x].append(Tile.Filler.Type)
			tile_instance_map[x].append([])
			set_tile(x, y, Tile.Filler.Type)

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
			create_enemy(x, y)
	
	# place an object in the start room
	var object_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2)
	var object_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2)
	create_breakable_object(object_x, object_y, Tile.CeramicPot.Type)
	
	
	# place an enemy in the start room
	var enemy_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2)
	var enemy_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2)
	create_enemy(enemy_x, enemy_y)

	# Place stairs to get to next stage
	var end_room = rooms.back()
	var stairs_x = end_room.position.x + 1 + randi() % int(end_room.size.x - 2)
	var stairs_y = end_room.position.y + 1 + randi() % int(end_room.size.y - 2)
	set_tile(stairs_x, stairs_y, Tile.StairsNE.Type)

	# Wait and update stage visuals
	yield(get_tree().create_timer(.1), "timeout") ## gives time to update visuals
	call_deferred("update_visuals")	

# Set visuals for current state
func update_visuals():
	var player_position = map.map_to_world(player_tile)
	player.position.x = player_position.x
	player.position.y = player_position.y + 32
	player.destination = player.position
	
	map.clear()
	populate_floor_map()
	map.initiate_map_details()

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
			set_tile(x, start_y, Tile.WallN.Type) 
		elif x == (start_x + size_x - 1): 
			set_tile(x, start_y, Tile.WallE.Type)
		else: 
			set_tile(x, start_y, Tile.WallNE.Type)
			
		if x == start_x:
			set_tile(x, start_y + size_y - 1, Tile.WallW.Type)
		elif x == (start_x + size_x - 1): 
			set_tile(x, start_y + size_y - 1, Tile.WallS.Type)
		else: 
			set_tile(x, start_y + size_y - 1, Tile.WallSW.Type)

	for y in range(start_y + 1, start_y + size_y - 1):
		set_tile(start_x, y, Tile.WallNW.Type)
		set_tile(start_x + size_x -1, y, Tile.WallSE.Type)
		
		for x in range(start_x + 1, start_x + size_x - 1):
			set_tile(x, y, Tile.BlankGround.Type)

	cut_regions(free_regions, room)

# Place tile type at location
func set_tile(x, y, type):
	# delete tile instance at location
	if typeof(tile_instance_map[x][y]) == TYPE_OBJECT:
		tile_instance_map[x][y].queue_free()
		tile_instance_map[x][y] = -1
	# save tile type in map
	tile_map[x][y] = type
	
	# create tile on position x, y
	if type == Tile.BlankGround.Type:
		map.set_cell(x, y, type)
		clear_path(Vector2(x, y))
	else:
		create_tile(x, y, type)
		
		# fill ground undearneath the wall and tiles
#		if is_wall(type) || is_door(type):
#			map.set_cell(x, y, Tile.BlankGround.Type)

# Create tile instance from scene and position it on the map
func create_tile(x, y, type, to_wall_map = true):
	
	# create and add to map
	var tile = get_tile_by_type(type).Scene.instance()
	if null != tile.get("type"): tile.type = type
	# add to wall_map or floor_map (used in populate_floor_map)
	if to_wall_map:
		wall_map.add_child(tile)
	else:
		floor_map.add_child(tile)
	
	# set tile position with offset
	var position = map.map_to_world(Vector2(x, y))
	var tile_offset = get_tile_by_type(type).Offset
	tile.position.x = position.x + tile_offset.x
	tile.position.y = position.y + tile_offset.y
	if to_wall_map:
		tile_instance_map[x][y] = tile
	
	# hide the tile upon creation
	tile.visible = false

# check if tile is a wall
func is_wall(type):
	return type == Tile.WallN.Type || Tile.WallNE.Type || Tile.WallE.Type || Tile.WallSE.Type || Tile.WallS.Type || Tile.WallSE.Type || Tile.WallW.Type || Tile.WallNW.Type
	
# clear path
func clear_path(tile):
	var new_point = pathfinding.get_available_point_id()
	pathfinding.add_point(new_point, Vector3(tile.x, tile.y, 0))
	var points_to_connect = []
	
	if tile.x > 0 && tile_map[tile.x -1][tile.y] == Tile.BlankGround.Type:
		points_to_connect.append(pathfinding.get_closest_point(Vector3(tile.x - 1, tile.y, 0)))
	if tile.y > 0 && tile_map[tile.x][tile.y - 1] == Tile.BlankGround.Type:
		points_to_connect.append(pathfinding.get_closest_point(Vector3(tile.x, tile.y - 1, 0)))
	if tile.x < stage_size.x - 1 && tile_map[tile.x + 1][tile.y] == Tile.BlankGround.Type:
		points_to_connect.append(pathfinding.get_closest_point(Vector3(tile.x + 1, tile.y, 0)))
	if tile.y < stage_size.y - 1 && tile_map[tile.x][tile.y + 1] == Tile.BlankGround.Type:
		points_to_connect.append(pathfinding.get_closest_point(Vector3(tile.x, tile.y + 1, 0)))

	for point in points_to_connect:
		pathfinding.connect_points(point, new_point)


func connect_rooms():
	# Build an AStar graph of the area where we can add corridors
	
	var block_graph = AStar.new()
	var point_id = 0
	for x in range(stage_size.x):
		for y in range(stage_size.y):
			if tile_map[x][y] == Tile.Filler.Type:
				block_graph.add_point(point_id, Vector3(x, y, 0))
				
				# Connect to left if also Filler
				if x > 0 && tile_map[x - 1][y] == Tile.Filler.Type:
					var left_point = block_graph.get_closest_point(Vector3(x - 1, y, 0))
					block_graph.connect_points(point_id, left_point)
					
				# Connect to above if also Filler
				if y > 0 && tile_map[x][y - 1] == Tile.Filler.Type:
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
		set_tile(position.x, position.y, Tile.BlankGround.Type)

	room_graph.connect_points(start_room_id, end_room_id)

# set the door tile, open or closed based on the wall orientation next to it
func set_door_tile(position_x, position_y, open):
	if Tile.WallNE.Type == tile_map[position_x - 1][position_y] || Tile.WallNE.Type == tile_map[position_x + 1][position_y]:
		if open:
			set_tile(position_x, position_y, Tile.DoorOpenNE.Type)
		else:
			set_tile(position_x, position_y, Tile.DoorNE.Type)
	elif Tile.WallSE.Type == tile_map[position_x][position_y - 1] || Tile.WallSE.Type == tile_map[position_x][position_y + 1]:
		if open:
			set_tile(position_x, position_y, Tile.DoorOpenSE.Type)
		else:
			set_tile(position_x, position_y, Tile.DoorSE.Type)
	elif Tile.WallSW.Type == tile_map[position_x - 1][position_y] || Tile.WallSW.Type == tile_map[position_x + 1][position_y]:
		if open:
			set_tile(position_x, position_y, Tile.DoorOpenSW.Type)
		else:
			set_tile(position_x, position_y, Tile.DoorSW.Type)
	elif Tile.WallNW.Type == tile_map[position_x][position_y - 1] || Tile.WallNW.Type == tile_map[position_x][position_y + 1]:
		if open:
			set_tile(position_x, position_y, Tile.DoorOpenNW.Type)
		else:
			set_tile(position_x, position_y, Tile.DoorNW.Type)

func is_door(type):
	return type == Tile.DoorNE.Type || type == Tile.DoorSE.Type || type == Tile.DoorSW.Type || type == Tile.DoorNW.Type || type == Tile.DoorOpenNE.Type || type == Tile.DoorOpenSE.Type || type == Tile.DoorOpenSW.Type || type == Tile.DoorOpenNW.Type

func is_door_closed(type):
	return type == Tile.DoorNE.Type || type == Tile.DoorSE.Type || type == Tile.DoorSW.Type || type == Tile.DoorNW.Type

func is_breakable_object(type):
	return type == Tile.CeramicPot.Type

func hurt(target):
	target.health -= 1
	if target.health <= 0:
		target.remove()
		var index = object_instance_list.find(target)
		object_instance_list.erase(object_instance_list[index])

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

func populate_floor_map():
	# create a stage of blank floor scenes with collision to be revealed by player
	for x in stage_size.x:
		for y in stage_size.y:
			if tile_map[x][y] == Tile.BlankGround.Type || is_door(tile_map[x][y]):
				create_tile(x, y, Tile.Ground.Type, false)

func is_walkable_tile(type):
	return type == Tile.Ground.Type || type == Tile.BlankGround.Type || is_door(type)

# ==============================================================================
# ---------------------------- Breakable Object -------------------------------
# ==============================================================================

func create_breakable_object(x, y, type):
	var breakable_object = get_tile_by_type(type).Scene.instance(type)
	var world_pos = map.map_to_world(Vector2(x, y))
	breakable_object.position.x = world_pos.x
	breakable_object.position.y = world_pos.y
	wall_map.add_child(breakable_object)
	# add object to lists
	object_instance_list.append(breakable_object)

# ==============================================================================
# ---------------------------------- Enemy -------------------------------------
# ==============================================================================

func create_enemy(x, y):
	var enemy = EnemyScene.instance()
	enemy.tile = Vector2(x, y)
	enemy.position = map.map_to_world(enemy.tile)
	enemy.position.y += 32
	enemies.append(enemy)
	self.add_child(enemy)

# ==============================================================================
# ----------------------------------- Tools ------------------------------------
# ==============================================================================

# return the Tile key in the dictionary
func get_tile_by_type(type):
	for key in Tile.keys():
		if Tile[key].Type == type:
			return Tile[key] 

# return the object by id
func get_object_by_id(id):
	for object in object_instance_list:
		if object.get_instance_id() == id:
			return object 

func print_msg(msg):
	ui.print_msg(msg)
	
func gen_rand_num(min_range, max_range, return_integer = false):
	randomize()
	if return_integer:
		return rand_range(min_range, max_range)
	else:
		return round(rand_range(min_range, max_range))

func get_tile_center_position(position):
	# global position is translated to map position and then back to global
	# an offset in y will put it in the center of the tile
	var middle_of_tile =  map.map_to_world(map.world_to_map(position))
	middle_of_tile.y  += TILE_SIZE.y / 2
	return middle_of_tile
