extends Control

onready var Buttons = $Menu/centerRow/Buttons

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if $OptionsMenu.visible == true:
		$Menu.visible = false
	else:
		$Menu.visible = true


func _input(_event):
	pass


func _on_StartGame_pressed() -> void:
	get_tree().change_scene("res://LVLs/LVL_0.tscn")


func _on_Options_pressed() -> void:
	$OptionsMenu/AnimationPlayer.play("FadeIn")
	$OptionsMenu.visible = true


func _on_Exit_Game_pressed() -> void:
	get_tree().quit()
