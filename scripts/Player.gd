extends KinematicBody2D

const PlayerHurtSound = preload("res://PlayerHurtSound.tscn")
const CompositeSprites = preload("res://scenes/CompositeSprites.gd")
const PlayerDetection = preload("res://Enemies/PlayerDetection.tscn")

export var ACCELERATION = 500
export var MAX_SPEED = 40
export var BLOCK_SPEED = -50
export var FRICTION = 500

enum {
	MOVE,
	ATTACK1,
	ATTACK2,
	ATTACK3,
	BLOCK,
	REST,
}

var state = MOVE
var velocity = Vector2.ZERO
var block_vector = Vector2.DOWN
var stats = PlayerStats
var avoid_force: int = 70
var max_steering: float = 0.9
var reached_destination: bool 

var path: Array = []
var levelNav: Navigation2D = null
var enemy = null



onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var armoranimationPlayer = $CompositeSprites.armoranimationPlayer
onready var nobleanimationPlayer = $CompositeSprites.nobleanimationPlayer
onready var elvenanimationPlayer = $CompositeSprites.elvenanimationPlayer
onready var flowinganimationPlayer = $CompositeSprites.flowinganimationPlayer
onready var eyeanimationPlayer = $CompositeSprites.eyeanimationPlayer
onready var armoranimationState = $CompositeSprites.armoranimationState
onready var nobleanimationState = $CompositeSprites.nobleanimationState
onready var elvenanimationState = $CompositeSprites.elvenanimationState
onready var flowinganimationState = $CompositeSprites.flowinganimationState
onready var eyeanimationState = $CompositeSprites.eyeanimationState
onready var hurtbox = $Hurtbox
onready var raycasts: Node2D = get_node("Raycasts")

var timer = null
var timer_delay = 2

func _physics_process(delta):
	update()
	if not enemy:
		 find_enemy()
	if enemy and levelNav && reached_destination == false:
		if path.size() <= 0:
			generate_path()
		velocity += avoid_obstacles()
	velocity = velocity.clamped(MAX_SPEED)
	
	velocity = move_and_slide(velocity)
	
	match state:
		MOVE:
			move_state(delta)
		ATTACK1:
			Attack1()
		ATTACK2:
			Attack2()
		ATTACK3:
			Attack3()
		BLOCK:
			block_state()
		REST:
			rest_state()
			
func _ready():
	yield(get_tree(), "idle_frame")
	var tree = get_tree()
	if tree.has_group("LevelNav"):
		levelNav = tree.get_nodes_in_group("LevelNav")[0]
	if tree.has_group("Enemy"):
		enemy = tree.get_nodes_in_group("Enemy")[0]
	randomize()
	stats.connect("no_health", self, "rest_state")
	animationTree.active = true
	timer = Timer.new()
	timer.set_one_shot(false)
	timer.set_wait_time(timer_delay)
	timer.connect("timeout", self, "on_timeout_complete")
	add_child(timer)
	timer.start()
func on_timeout_complete():
	if state == REST:
		 stats.health += 1
		
func navigate() -> Vector2:
	if path.size() > 0:
		while path.size() > 0 and global_position.distance_to(path[0]) <= 6:
			path.pop_front()
			if path.size() <= 0:
				reached_destination = true
				return Vector2.ZERO
		return global_position.direction_to(path[0]) * MAX_SPEED
	return Vector2.ZERO
	
func generate_path():
	if levelNav != null and enemy != null:
		path = levelNav.get_simple_path(global_position, enemy.global_position, true)

func avoid_obstacles() -> Vector2:
	var avoid_vel = Vector2.ZERO
	var nav = navigate()
	raycasts.rotation = nav.angle()
	
	for raycast in raycasts.get_children():
		if raycast.is_colliding():
			var navigate_slide = navigate().slide(raycast.get_collision_normal())
			if navigate_slide.is_equal_approx(Vector2.ZERO):
				avoid_vel += nav.normalized().rotated(deg2rad(90))
			else:
				avoid_vel += navigate_slide.normalized()
	return (avoid_vel + nav).normalized() * MAX_SPEED
	
func find_enemy():
	for e in get_tree().get_nodes_in_group("enemies"):
		print(e)
		if e != enemy:
			print(e)
			enemy = e
			reached_destination = false
			return
	enemy = null
	
func _draw():
	for p in path.size() - 1:
		draw_circle(to_local(path[p]), 4, Color.white)
		if p+1 < path.size() - 1:
			draw_line(to_local(path[p]), to_local(path[p+1]), Color.white)
	
func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		block_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		$CompositeSprites.armoranimationTree.set("parameters/Idle/blend_position", input_vector)
		$CompositeSprites.nobleanimationTree.set("parameters/Idle/blend_position", input_vector)
		$CompositeSprites.elvenanimationTree.set("parameters/Idle/blend_position", input_vector)
		$CompositeSprites.flowinganimationTree.set("parameters/Idle/blend_position", input_vector)
		$CompositeSprites.eyeanimationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Walk/blend_position", input_vector)
		$CompositeSprites.armoranimationTree.set("parameters/Walk/blend_position", input_vector)
		$CompositeSprites.nobleanimationTree.set("parameters/Walk/blend_position", input_vector)
		$CompositeSprites.elvenanimationTree.set("parameters/Walk/blend_position", input_vector)
		$CompositeSprites.flowinganimationTree.set("parameters/Walk/blend_position", input_vector)
		$CompositeSprites.eyeanimationTree.set("parameters/Walk/blend_position", input_vector)
		animationTree.set("parameters/Attack1/blend_position", input_vector)
		$CompositeSprites.armoranimationTree.set("parameters/Attack1/blend_position", input_vector)
		$CompositeSprites.nobleanimationTree.set("parameters/Attack1/blend_position", input_vector)
		$CompositeSprites.elvenanimationTree.set("parameters/Attack1/blend_position", input_vector)
		$CompositeSprites.flowinganimationTree.set("parameters/Attack1/blend_position", input_vector)
		$CompositeSprites.eyeanimationTree.set("parameters/Attack1/blend_position", input_vector)
		animationTree.set("parameters/Attack2/blend_position", input_vector)
		$CompositeSprites.armoranimationTree.set("parameters/Attack2/blend_position", input_vector)
		$CompositeSprites.nobleanimationTree.set("parameters/Attack2/blend_position", input_vector)
		$CompositeSprites.elvenanimationTree.set("parameters/Attack2/blend_position", input_vector)
		$CompositeSprites.flowinganimationTree.set("parameters/Attack2/blend_position", input_vector)
		$CompositeSprites.eyeanimationTree.set("parameters/Attack2/blend_position", input_vector)
		animationTree.set("parameters/Attack3/blend_position", input_vector)
		$CompositeSprites.armoranimationTree.set("parameters/Attack3/blend_position", input_vector)
		$CompositeSprites.nobleanimationTree.set("parameters/Attack3/blend_position", input_vector)
		$CompositeSprites.elvenanimationTree.set("parameters/Attack3/blend_position", input_vector)
		$CompositeSprites.flowinganimationTree.set("parameters/Attack3/blend_position", input_vector)
		$CompositeSprites.eyeanimationTree.set("parameters/Attack3/blend_position", input_vector)
		animationTree.set("parameters/Block/blend_position", input_vector)
		$CompositeSprites.armoranimationTree.set("parameters/Block/blend_position", input_vector)
		$CompositeSprites.nobleanimationTree.set("parameters/Block/blend_position", input_vector)
		$CompositeSprites.elvenanimationTree.set("parameters/Block/blend_position", input_vector)
		$CompositeSprites.flowinganimationTree.set("parameters/Block/blend_position", input_vector)
		$CompositeSprites.eyeanimationTree.set("parameters/Block/blend_position", input_vector)
		animationTree.set("parameters/Rest/blend_position", input_vector)
		$CompositeSprites.armoranimationTree.set("parameters/Rest/blend_position", input_vector)
		$CompositeSprites.nobleanimationTree.set("parameters/Rest/blend_position", input_vector)
		$CompositeSprites.elvenanimationTree.set("parameters/Rest/blend_position", input_vector)
		$CompositeSprites.flowinganimationTree.set("parameters/Rest/blend_position", input_vector)
		
		animationState.travel("Walk")
		armoranimationState.travel("Walk")
		nobleanimationState.travel("Walk")
		elvenanimationState.travel("Walk")
		flowinganimationState.travel("Walk")
		eyeanimationState.travel("Walk")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		 animationState.travel("Idle")
		 armoranimationState.travel("Idle")
		 nobleanimationState.travel("Idle")
		 elvenanimationState.travel("Idle")
		 flowinganimationState.travel("Idle")
		 eyeanimationState.travel("Idle")
		 velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	move()
	
	if stats.health <= 0:
		state = REST
	elif Input.is_action_just_pressed("attack1"):
		state = ATTACK1
	elif Input.is_action_just_pressed("attack2"):
		state = ATTACK2
	elif Input.is_action_just_pressed("attack3"):
		state = ATTACK3
	else: 
		state = MOVE
	if Input.is_action_just_pressed("block"):
		state = BLOCK

func block_state():
	velocity = block_vector * BLOCK_SPEED
	animationState.travel("Block")
	armoranimationState.travel("Block")
	nobleanimationState.travel("Block")
	elvenanimationState.travel("Block")
	flowinganimationState.travel("Block")
	eyeanimationState.travel("Block")
	move()

func Attack1():
	velocity = Vector2.ZERO
	animationState.travel("Attack1")
	armoranimationState.travel("Attack1")
	nobleanimationState.travel("Attack1")
	elvenanimationState.travel("Attack1")
	flowinganimationState.travel("Attack1")
	eyeanimationState.travel("Attack1")
func Attack2():
	velocity = Vector2.ZERO
	animationState.travel("Attack2")
	armoranimationState.travel("Attack2")
	nobleanimationState.travel("Attack2")
	elvenanimationState.travel("Attack2")
	flowinganimationState.travel("Attack2")
	eyeanimationState.travel("Attack2")
func Attack3():
	velocity = Vector2.ZERO
	animationState.travel("Attack3")
	armoranimationState.travel("Attack3")
	nobleanimationState.travel("Attack3")
	elvenanimationState.travel("Attack3")
	flowinganimationState.travel("Attack3")
	eyeanimationState.travel("Attack3")
	
func rest_state():
	velocity = Vector2.ZERO
	animationState.travel("Rest")
	armoranimationState.travel("Rest")
	nobleanimationState.travel("Rest")
	elvenanimationState.travel("Rest")
	flowinganimationState.travel("Rest")
	$CompositeSprites/Eye.hide()
	hurtbox.collisionShape.disabled = true
	
func move():
	velocity = move_and_slide(velocity)
	
func block_animation_finished():
	state = MOVE

func attack_animation_finished():
	state = MOVE

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.6)
	hurtbox.create_hit_effect()
	var playerHurtSound = PlayerHurtSound.instance()
	get_tree().current_scene.add_child(playerHurtSound)
	
