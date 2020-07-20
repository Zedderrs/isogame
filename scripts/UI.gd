extends Control

onready var game = get_tree().get_root().get_node("Game")
# UI nodes
onready var hp_bar = $Status/HP
onready var xp_bar = $Status/XP
onready var hp = $Status/Portrait/HP
onready var xp = $Status/Portrait/XP

onready var hp_max_length = hp_bar.scale.x
onready var xp_max_length = xp_bar.scale.x

func _physics_process(_delta):
	# update hp
	hp.text = "HP: " + str(game.player.hp) + " / " + str(game.player.hp_max)
	hp_bar.scale.x  = float(float(game.player.hp) / float(game.player.hp_max)) * hp_max_length
	
	# update XP
	xp.text = "XP: " + str((game.player.xp / game.player.xp_max) * 100) + " %"
	xp_bar.scale.x  = float(float(game.player.xp) / float(game.player.xp_max)) * xp_max_length
