extends Control

onready var game = get_tree().get_root().get_node("Game")
# UI nodes
onready var hp_bar = $Status/HP
onready var xp_bar = $Status/XP
onready var hp = $Status/Portrait/HP
onready var xp = $Status/Portrait/XP
onready var msg_log = $MessageLog
onready var msg_log_scroll_container = $MessageLog/PanelLog/ScrollContainerLog
onready var msg_log_scroll_bar = msg_log_scroll_container.get_v_scrollbar()
onready var msg_log_list = $MessageLog/PanelLog/ScrollContainerLog/MessageLogList

onready var hp_max_length = hp_bar.scale.x
onready var xp_max_length = xp_bar.scale.x

func _physics_process(_delta):
	# update hp
	hp.text = "HP: " + str(game.player.hp) + " / " + str(game.player.hp_max)
	hp_bar.scale.x  = float(float(game.player.hp) / float(game.player.hp_max)) * hp_max_length
	
	# update XP
	xp.text = "XP: " + str((game.player.xp / game.player.xp_max) * 100) + " %"
	xp_bar.scale.x  = float(float(game.player.xp) / float(game.player.xp_max)) * xp_max_length


# ==============================================================================
# ----------------------------------- Message Box ------------------------------------
# ==============================================================================

func print_msg(msg):
	var label = Label.new()
	label.text = str(msg)
	msg_log_list.add_child(label)
	msg_log_scroll_container.scroll_vertical = msg_log_scroll_bar.max_value

func msg_log_toggle_visibility():
	msg_log.visible = !msg_log.visible
	
