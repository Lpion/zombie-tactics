extends Node
# Release 01.06.2020
# Version 1.0

# This script is autoloaded as singleton.
# It is set up in "ProectSettings/Autoload"
var playerDead = false
var lookDirection = Vector3()
var enemyLookDirection = Vector3()
var PlayerPosition = Vector3()

var MasterVol = 0
var MusicVol = 0
var EffectsVol = 0

var KillCount = -1
var GameTime = 0


func _ready() -> void:
	pass

# Close Game on Esc
func _input(_event):
	if Input.is_action_just_pressed("RESTART"):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("PRINT"):
		pass


# HP - System
# call with HEALTH = Global.damage(5, HEALTH, MAX_HEALTH)
# Function to be called on dmg, to set new health
func set_health(amount, HEALTH, MAX_HEALTH):
		var prev_health = HEALTH
		HEALTH = min(HEALTH + amount, MAX_HEALTH)
		if HEALTH != prev_health:
			return HEALTH
