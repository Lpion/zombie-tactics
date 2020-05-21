extends Spatial

func _ready() -> void:
	pass

func updateHP(currentHealth):
	$Viewport/Bar.value = currentHealth
	if(currentHealth <= 0):
		queue_free()
