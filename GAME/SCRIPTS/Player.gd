extends KinematicBody

#imports
var Bullet = preload("res://ASSETS/PRE_FABS/Weapons/Bullet.tscn")

export(float, 0, 1, 0.01) var WALK_FACTOR : float = 0.9
export var MAX_SPEED : float = 6
export(float, 0, 100, 0.01) var FRICTION : float = 100
export(float, 0, 100, 0.01) var ACCELARATION : float = 30
export(float, 0, 999, 0.01) var GRAVITY : float = 150
export(float) var MAX_HEALTH = 100

var CAN_SHOOT = false # false if no bullets && mags anymore, no shoot before spawn anim is done
var CAN_MOVE = false  # player can not move on init, but after spawn anim
var CAN_FEED = false
var FEED_AMOUNT = 1
var feedDone = false

var MAX_MAGS = 3 # can only pick up new mags if CURRENT_MAGS < MAX_MAGS
var CURRENT_MAGS = 1 # currently owned mags, can only be <= MAX_MAGS
var MAX_BULLETS_MAG = 100 # bullets in mag after reload
var CURRENT_BULLETS_MAG = MAX_BULLETS_MAG # current bullets in mag

var moveDirection = Vector3()
var vel = Vector3() # Velocity = speed with a direction
var healthRegenCounter = 0

onready var HEALTH = MAX_HEALTH

# Save nodes into vars
onready var Cam = $CameraRig/Camera
onready var CamRig = $CameraRig
onready var Cursor = $Cursor
onready var AnimTree = $AnimationTree
onready var BulletEmitter = $Body/Skeleton/BoneAttachment/Shotgun/BulletEmitter
onready var DebugVel = $DebugHUD/Velocity
onready var DebugDir = $DebugHUD/Direction
onready var DebugHP  = $DebugHUD/HP
onready var DebugAmmo  = $DebugHUD/Ammo
onready var PlayerBody = $"/root/Global"


func _ready():
	# disable player during spawn phase
#	disable_player()
#	# Things to do right after the Spawn anim
#	# wait for the anim to finish
#	yield($AnimationPlayer, "animation_finished")
	enable_player()

	# Ignore parent node transforms
	# This is so that the Cam and rig stays in place when the player transforms
	CamRig.set_as_toplevel(true)
	Cursor.set_as_toplevel(true)


func _physics_process(delta):
	Global.PlayerPosition = self.get_translation()
	debug()
	#control Cam
	cam_follows_player()
	rot_cam()
	#move player
	if CAN_MOVE:
		look_at_cursor()
		get_move_input()
		move(delta)
	#animate player
	player_anim()
	check_ammo()
	reload()
	shooting()
	feed()
	if healthRegenCounter >= 1:
		increase_health_over_time()

func debug():
	DebugDir.text = "Direction \n X = " + str(round(-Global.lookDirection.x)) + "\n z = " + str(round(-Global.lookDirection.z))
	DebugAmmo.text = "MAGS " + str(CURRENT_MAGS) + "\n BULLETS " + str(CURRENT_BULLETS_MAG)
	DebugHP.text = str(HEALTH)

func disable_player():
	CAN_MOVE = false
	CAN_SHOOT = false
	$Cursor.visible = false
func enable_player():
	CAN_MOVE = true
	CAN_SHOOT = true
	$Cursor.visible = true

# get origins of player and CamRig
# and set CamRig to the same position as player
func cam_follows_player():
	var playerPos = global_transform.origin
	CamRig.global_transform.origin = playerPos

# Rotate Cam 180 deg on button press
func rot_cam():
	if Input.is_action_just_pressed("ROT_CAM"):
		CamRig.rotate_y(deg2rad(180))


# Take 2D mouse position relative to the screen
# and use it to calculate the position of the 3D Cursor
func look_at_cursor():
	# Set global lookDirection, to have eg a reference for the bullet
	Global.lookDirection = get_global_transform().basis.z

	# Create hoz place, and find point where the ray intersects with it
	var playerPos = global_transform.origin
	# first param is the planes normal = UP = horizontal plane on the floor
	# second param sets the vertical position of the plane , to the one of the player (in case of jumping, etc.)
	var dropPlane = Plane(Vector3.UP, playerPos.y)

	# Project a ray from Cam, from where the mouse Cursor is in 2D viewport
	var rayLength = 1000
	var mousePos = get_viewport().get_mouse_position() # get mouse position
	# shoot a ray ...
	var from = Cam.project_ray_origin(mousePos)
	var to = from + Cam.project_ray_normal(mousePos) * rayLength # ... to the direction the Cam is pointing at
	var cursorPos = dropPlane.intersects_ray(from, to) # determine intersection point from the ray with the plane

	# Set global position of the Cursor node to cursorPos + 1 UP , so it is at players height
	Cursor.global_transform.origin = cursorPos + Vector3.UP
	# make player always look at cursorPos
	look_at(cursorPos, Vector3.UP)


# move player relative to the camera
func get_move_input():
	moveDirection = Vector3()
	# we need to get the camera global basis (global XYZ),
	# to move in the global and not the local Cam axis
	var camBasis = Cam.get_global_transform().basis

	# move player pos/neg, on global Cam.axis
	if Input.is_action_pressed("FORWARD") : moveDirection -= camBasis.z * 1.8 # 1.8 = correct diagonal movement
	elif Input.is_action_pressed("BACKWARDS") : moveDirection += camBasis.z * 1.8 # 1.8 = correct diagonal movement
	if Input.is_action_pressed("LEFT") : moveDirection -= camBasis.x
	elif Input.is_action_pressed("RIGHT") : moveDirection += camBasis.x

	moveDirection.y = 0 # ignore Cam tilt
	moveDirection = moveDirection.normalized() # normalize to make sure Vector length = 1

# execute movement
func move(delta):
	# when no player input => apply_friction, so the character comes to a stop
	# else apply_movement, so the character can accelarate
# warning-ignore:standalone_ternary
	apply_friction(FRICTION * delta) if moveDirection == Vector3.ZERO else apply_movement(moveDirection * ACCELARATION * delta)

	# apply Gravity
	vel.y -= GRAVITY * delta

	DebugVel.text = "Velocity \nX = " + str(round(vel.x)) + "\n" + "Z = " + str(round(vel.z))

	# execute actual movement
	vel = move_and_slide(vel, Vector3.UP, true, 1)

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

# Check for ammo in current MAG
func check_ammo():
	# if no mags or bullets in current mag stop shooting
	if CURRENT_BULLETS_MAG == 0:
		CAN_SHOOT = false

# Reload, possible if there are any MAGs left
func reload():
	if Input.is_action_just_pressed("RELOAD") && (CURRENT_MAGS > 0):
		CURRENT_BULLETS_MAG = MAX_BULLETS_MAG
		CURRENT_MAGS -= 1
		CAN_SHOOT = true

# Shooting, possible if there are bullets in the current mag
func shooting():
	if Input.is_action_pressed("SHOOT") && CAN_SHOOT:
		AnimTree["parameters/Transition/current"] = 1

		# Bullet = Ref to Bullet Scene
		var bullet = Bullet.instance()
		# remove 1 bullet from current mag
		CURRENT_BULLETS_MAG -= 1
		# spawn bullet
		BulletEmitter.add_child(bullet)
		var BulletDir = Vector3(-Global.lookDirection.x,0 , -Global.lookDirection.z)
		var BulletDmg = 10
		bullet.on_pew(BulletDir, BulletDmg)
		bullet.set_as_toplevel(true)

		CAN_SHOOT = false
		yield(get_tree().create_timer(0.2), "timeout")
		CAN_SHOOT = true

	if Input.is_action_just_released("SHOOT") || (CURRENT_BULLETS_MAG == 0):
		AnimTree["parameters/Transition/current"] = 0


func hit(dmg):
	HEALTH = Global.set_health(-dmg, HEALTH, MAX_HEALTH)
	if (HEALTH <= 0):
		dead()

func dead():
	AnimTree["parameters/Transition/current"] = 2
	disable_player()
	Global.playerDead = true



func pickup_magazine():
	if CURRENT_MAGS != MAX_MAGS:
		$PickupParticle.emitting = true
		CURRENT_MAGS += 1

func feed():
	if Input.is_action_just_pressed("FEED") && CAN_FEED && (HEALTH < MAX_HEALTH):

		# activate counter for HP-Regen
		healthRegenCounter = 1
		$HealParticle.emitting = true

		# Play anim then wait for finish before proceeding
		$AnimationPlayer.play("Biting-loop")
		# disable movement and shooting
		disable_player()
		# wait for animation to finish
		yield($AnimationPlayer, "animation_finished")
		after_feed()

func after_feed():
	enable_player()
	# deactivate counter for HP-Regen
	healthRegenCounter = 0
	feedDone = true
	$HealParticle.emitting = false


# Handle Animation States
func player_anim():
	# IDLE
	if vel.length() == 0:
		AnimTree["parameters/movement/blend_position"] = Vector2(0, 0)
	# MOVE
	else:
		AnimTree["parameters/movement/blend_position"] = Vector2(vel.x / MAX_SPEED, -vel.z / MAX_SPEED)

# Health Regeneration
func increase_health_over_time():
	healthRegenCounter += 1
	if healthRegenCounter == 8 && HEALTH < MAX_HEALTH:
		healthRegenCounter = 1
		HEALTH = Global.set_health(FEED_AMOUNT, HEALTH, MAX_HEALTH)
