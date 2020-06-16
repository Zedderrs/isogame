extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# ==============================================================================
# ------------------ Player Input and Movement Mechanics -----------------------
# ==============================================================================

# scene components
onready var player = $Sprite

# pressed keys state object
class PressedKeys:
	var up = false
	var down = false
	var left = false
	var right = false
	var up_left = false
	var up_right = false
	var down_left = false
	var down_right = false
	
	func update_state(event):
		if event.is_pressed():
			update_pressed(event)
		else:
			update_release(event)
			
	func update_pressed(_event):
		pass
	
	func update_release(_event):
		pass

var pressed_keys = PressedKeys.new()

# Keyboard Input
func _input(event):
	event.is_pressed()
	print(pressed_keys.up)
	# Key Inputs
	if event.is_action("ui_up"):
		player.animation = "run_up"
	elif event.is_action("ui_down"):
		player.animation = "run_down"
	if event.is_action("ui_left"):
		player.animation = "run_left"
	elif event.is_action("ui_right"):
		player.animation = "run_right"
	elif event.is_action("ui_up") && event.is_action("ui_left"):
		player.animation = "run_up_left"
	elif event.is_action("ui_up") && event.is_action("ui_right"):
		player.animation = "run_up_right"
	elif event.is_action("ui_down") && event.is_action("ui_left"):
		player.animation = "run_down_left"
	elif event.is_action("ui_down") && event.is_action("ui_right"):
		player.animation = "run_down_right"	
