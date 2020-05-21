extends KinematicBody

export var BULLET_SPEED = 0.21

onready var direction
onready var dmg

func _process(_delta):
	on_pew(direction, dmg)

func on_pew(BulletDir, BulletDmg):
	direction = BulletDir
	dmg = BulletDmg

	var collision = move_and_collide(direction * BULLET_SPEED)
	if collision:
		var object = collision.collider
		if object.has_method("hit"):
			object.hit(dmg)
		queue_free()
