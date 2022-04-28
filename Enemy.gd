extends KinematicBody2D

var speed = 100  # speed in pixels/sec
var velocity = Vector2.ZERO
var current_animation
var local = false
var attacking = false
var go_right = false
var go_left = false
var go_up = false
var go_down = false
var go_attack = false
var target_pos

func _ready():
	set_process(false)
	set_physics_process(false)
	Net.realtime_group_add("slime")

func control_local():
	local = true
	set_process(true)
	set_physics_process(true)

func hit():
	set_process(false)
	set_physics_process(false)
	anim("die")
	yield($AnimatedSprite, "animation_finished")
	Net.sync_rpc("slime", self, name.validate_node_name(), "queue_free")
	queue_free()

func sync_pos(x, y):
	if attacking: return
	var dx = x - global_position.x
	var dy = y - global_position.y
	if dx > 1:
		get_node("AnimatedSprite").flip_h = false
	elif dx < -1:
		get_node("AnimatedSprite").flip_h = true
	if dx > 1 or dy > 1:
		anim('walk')
	elif dx < -1 or dy < -1:
		anim('walk')
	else:
		anim('idle')
	global_position.x = x
	global_position.y = y

func get_input():
	if attacking: return
	velocity = Vector2.ZERO
	if go_right:
		velocity.x += 1
		go_right = false
	if go_left:
		velocity.x -= 1
		go_left = false
	if go_down:
		velocity.y += 1
		go_down = false
	if go_up:
		velocity.y -= 1
		go_up = false
	velocity = velocity.normalized() * speed
	if velocity.x > 1:
		$AnimatedSprite.flip_h = false
	elif velocity.x < -1:
		$AnimatedSprite.flip_h = true
	if velocity.x > 1 or velocity.y > 1:
		anim('walk')
	elif velocity.x < -1 or velocity.y < -1:
		anim('walk')
	else:
		anim('idle')
	if go_attack:
		go_attack = false
		attack("")
		Net.sync_rpc("slime", self, name.validate_node_name(), "attack")

func _process(_delta):
	Net.sync_pos("slime", self, name.validate_node_name())

func _physics_process(_delta):
	get_ai()
	get_input()
	velocity = move_and_slide(velocity)

func attack(_arg: String):
	Net.sync_rpc("slime", self, name.validate_node_name(), "attack")
	attacking = true
	anim('attack')
	velocity = Vector2.ZERO
	yield($AnimatedSprite, "animation_finished")
	attacking = false

func anim(animation):
	if current_animation != animation:
		$AnimatedSprite.play(animation)
		current_animation = animation

var nearest_player_distance
var nearest_player
func get_ai():
	if not target_pos: return
	if target_pos.x+3 > global_position.x:
		go_right = true
	if target_pos.x-3 < global_position.x:
		go_left = true
	if target_pos.y+3 > global_position.y:
		go_down = true
	if target_pos.y-3 < global_position.y:
		go_up = true

func _on_Timer_timeout():
	target_pos = null
	var ps = get_tree().get_nodes_in_group("players")
	nearest_player_distance = 99999
	for p in ps:
		var distance = global_position.distance_to(p.global_position)
		if nearest_player_distance > distance:
			nearest_player_distance = distance
			nearest_player = p
	target_pos = nearest_player.global_position
