extends Node

# This script is autoloaded as singleton.
# It is set up in "ProectSettings/Autoload"
var playerDead = false
var lookDirection = Vector3()
var enemyLookDirection = Vector3()
var PlayerPosition = Vector3()

func _ready() -> void:
	# Hide mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# Close Game on Esc
func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
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
