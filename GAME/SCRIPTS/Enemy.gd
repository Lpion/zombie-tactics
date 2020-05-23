extends KinematicBody

#imports
var HPBar = preload("res://UI/HPBar.tscn")
var Bullet = preload("res://ASSETS/PRE_FABS/Weapons/Bullet.tscn")

export var SHOOTING_RANGE = 10
export var MAX_SPEED : float = 4
export(float, 0, 100, 0.01) var FRICTION : float = 100
export(float, 0, 100, 0.01) var ACCELARATION : float = 30
export(float, 0, 999, 0.01) var GRAVITY : float = 150
export var MAX_HEALTH = 100

var CAN_SHOOT = true
var isDead = false
var isHit = false
var playerDetected = false
var inShootingRange = false
var searchPlayer = false
var remove = false
var moveDirection = Vector3()
var vectorToPlayer = Vector3()
var playerPos = Vector3()
var selfPos = Vector3()
var vel = Vector3()

onready var HEALTH = MAX_HEALTH
onready var HP = HPBar.instance()
onready var BulletEmitter = $Body/Skeleton/BoneAttachment/Rifle/BulletEmitter
onready var AnimTree = $AnimationTree

func _ready():
	# Add HP-Bar to Enemy
	$Body/Skeleton/HPBarPos.add_child(HP)

	# Tools
	$RangeCircle.scale = Vector3(SHOOTING_RANGE, 1, SHOOTING_RANGE)

func _process(delta):
	if(!isDead):
		look_at_player()
		check_shooting_range() #needs to be called after look_at_player
		move(delta)
		shooting()
		enemy_anim()
	if remove:
		removeCorpse()

# player detection
func _on_DetectionArea_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		playerDetected = true
func _on_DetectionArea_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		playerDetected = false
		# save last known location of player and start searching
		playerPos = Global.PlayerPosition
		searchPlayer = true


func look_at_player():
	selfPos = self.get_translation()

	# stop search for player at the last known location
	if selfPos.round() == playerPos.round():
		searchPlayer = false

	if playerDetected:
		playerPos = Global.PlayerPosition
		moveDirection = (playerPos-selfPos).normalized()
		vectorToPlayer = playerPos-selfPos

		look_at(playerPos, Vector3.UP)
		# set rotation after look_at with x,z = 0 so the enemy only rotates around the y axis
		set_rotation(Vector3(0, get_rotation().y, 0))
		# Rotate to player
		rotate(Vector3.UP, PI)

	# get the direction the enemy is faceing (for shooting)
	Global.enemyLookDirection = get_global_transform().basis.z


func check_shooting_range():
	# get distance to player
	var playerDistance = vectorToPlayer.length()

	# check if in shooting range
	if playerDistance <= SHOOTING_RANGE:
		inShootingRange = true
	if playerDistance > SHOOTING_RANGE:
		inShootingRange = false


func move(delta):
	# warning-ignore:standalone_ternary
	apply_friction(FRICTION * delta) if moveDirection == Vector3.ZERO else apply_movement(moveDirection * ACCELARATION * delta)
	# apply Gravity
	vel.y -= GRAVITY * delta
	# Move torwards player if detected or searching
	if playerDetected && !inShootingRange || searchPlayer:
		vel = move_and_slide(vel, Vector3.UP, true, 1)
	else:
		vel = Vector3()

func apply_movement(acceleration):
	# add amount of acc each frame until we hit our MAX_SPEED
	vel += acceleration
	# when MAX_SPEED reached, set vel to MAX_SPEED || TODO: maybe use clamp function instead of if
	if vel.length() > MAX_SPEED:
		vel = vel.normalized() * MAX_SPEED

func apply_friction(friction):
	# as long as the velocity is bigger than the friction ...
	if vel.length() > friction:
		vel -= vel.normalized() * friction * vel.length() # ... we can keep substracting friction from it
	# as soon we can not substract a full friction anymore, we just set veloctiy to 0
	else: vel = Vector3.ZERO

func shooting():
	if CAN_SHOOT && inShootingRange && playerDetected && !Global.playerDead:
		AnimTree["parameters/Transition/current"] = 2

		# Bullet = Ref to Bullet Scene
		var bullet = Bullet.instance()
		# spawn bullet
		BulletEmitter.add_child(bullet)
		var BulletDir = Vector3(Global.enemyLookDirection.x,0 , Global.enemyLookDirection.z)
		var BulletDmg = 5
		bullet.on_pew(BulletDir, BulletDmg)
		bullet.set_as_toplevel(true)
		$Body/Skeleton/BoneAttachment/Rifle/AudioStreamPlayer3D.playing = true
		CAN_SHOOT = false
		yield(get_tree().create_timer(0.2), "timeout")
		$Body/Skeleton/BoneAttachment/Rifle/AudioStreamPlayer3D.playing = false
		CAN_SHOOT = true

func hit(dmg):
	# set true to follow player
	isHit = true
	playerDetected = true

	$HitParticle.emitting = true
	HEALTH = Global.set_health(-dmg, HEALTH, MAX_HEALTH)
	#print(str(HEALTH))
	HP.updateHP(HEALTH)
	if (HEALTH <= 0):
		dead()

func dead():
	isDead = true
	AnimTree["parameters/Transition/current"] = 3
	$CollisionShape.disabled = true

	# Feed the player
	$FeedArea/CollisionShape.disabled = false

var player
func _on_FeedArea_body_entered(body: Node) -> void:
	if body.has_method("feed"):
		body.feedDone = false
		body.CAN_FEED = true
		player = body
		remove = true
func _on_FeedArea_body_exited(body: Node) -> void:
	if body.has_method("feed"):
		body.CAN_FEED = false
		remove = false

func removeCorpse():
	if player.feedDone:
		player.CAN_FEED = false
		queue_free()

# Handle Animation States
func enemy_anim():
	# IDLE
	if vel.length() == 0 && !playerDetected:
		AnimTree["parameters/Transition/current"] = 0
		$AudioStreamPlayer3D.playing = false
	# MOVE
	elif vel.length() > 0:
		AnimTree["parameters/Transition/current"] = 1
		if $AudioStreamPlayer3D.playing == false:
			$AudioStreamPlayer3D.playing = true
