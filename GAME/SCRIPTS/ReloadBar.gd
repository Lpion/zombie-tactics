extends Spatial

func _ready() -> void:
	pass

func updateProgress(currentProgress):
	$Viewport/Bar.value = currentProgress
	if(currentProgress == 100):
		queue_free()
