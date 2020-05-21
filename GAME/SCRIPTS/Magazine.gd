extends Area

func _ready():
	pass

# signal to self
# check if a body entered the Area and if it has a method
func body_enter(body: Node) -> void:
	if body.has_method("pickup_magazine"):
		body.pickup_magazine()
		# remove mag from floor only if player can pick it up
		if body.CURRENT_MAGS < body.MAX_MAGS:
			queue_free()
